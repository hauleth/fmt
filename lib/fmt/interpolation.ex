defmodule Fmt.Interpolation do
  alias Macro.Env

  @enforce_keys [:value]
  defstruct [
    :value,
    align: ?>,
    sign: nil,
    fill: " ",
    alternate: false,
    zero_pad: false,
    width: :infinity,
    precision: nil,
    type: nil
  ]

  def build(opts), do: struct!(__MODULE__, opts)

  defp get_var({:ident, name}, module),
    do: quote(do: var!(unquote(Macro.var(String.to_atom(name), module))))

  defp get_var(value, _module),
    do: value

  def to_quoted(%__MODULE__{value: name} = int, %Env{} = env) do
    variable = get_var(name, env.module)

    quote do
      unquote(__MODULE__).__format__(
        unquote(variable),
        %unquote(__MODULE__){
          value: unquote(variable),
          align: unquote(int.align),
          sign: unquote(int.sign),
          fill: unquote(int.fill),
          alternate: unquote(int.alternate),
          zero_pad: unquote(int.zero_pad),
          width: unquote(get_var(int.width, env.module)),
          precision: unquote(get_var(int.precision, env.module)),
          type: unquote(int.type)
        }
      )
    end
  end

  @doc false
  def __format__(value, %__MODULE__{type: type} = int) when is_integer(value) do
    {prefix, base} =
      case type do
        :hex -> {"0x", 16}
        :octal -> {"0o", 8}
        :binary -> {"0b", 2}
        _ -> {"", 10}
      end

    prefix =
      if not int.alternate do
        prefix
      else
        []
      end

    neg =
      cond do
        value < 0 -> "-"
        int.sign == ?+ -> "+"
        true -> ""
      end

    stringified = Integer.to_string(abs(value), base)

    if int.zero_pad and is_integer(int.width) do
      neg_size = IO.iodata_length(neg)
      prefix_size = IO.iodata_length(prefix)
      current_size = neg_size + prefix_size
      width = max(0, int.width - current_size)

      [neg, prefix, String.pad_leading(stringified, width, "0")]
    else
      pad([neg, prefix, stringified], int)
    end
  end

  def __format__(value, %__MODULE__{type: nil} = int) when is_float(value) do
    if int.precision == nil do
      :io_lib_format.fwrite_g(value)
    else
      options =
        [compact: true, decimals: int.precision]
        |> Enum.flat_map(fn
          {_, false} -> []
          {_, nil} -> []
          {k, true} -> [k]
          entry -> [entry]
        end)

      :erlang.float_to_binary(value, options)
    end
    |> IO.iodata_to_binary()
    |> pad(int)
  end

  def __format__(value, %__MODULE__{type: nil} = int) do
    pad(Kernel.to_string(value), int)
  end

  def __format__(value, %__MODULE__{} = int) do
    infer? = int.type in [:inspect, :raw]

    base =
      if int.type not in [:decimal, :hex, :octal, :binary] do
        :decimal
      else
        int.type
      end

    inspect_opts = %Inspect.Opts{
      width: int.width,
      base: base,
      binaries: if(infer?, do: :infer, else: :as_binaries),
      charlists: if(infer?, do: :infer, else: :as_lists),
      pretty: int.alternate,
      structs: int.type != :raw
    }

    doc = Inspect.Algebra.to_doc(value, inspect_opts)

    Inspect.Algebra.format(doc, int.width)
  end

  defp pad(value, %__MODULE__{width: :infinity}), do: value

  defp pad(value, %__MODULE__{width: width, fill: fill, align: ?>}),
    do: String.pad_leading(value, width, fill)

  defp pad(value, %__MODULE__{width: width, fill: fill, align: ?<}),
    do: String.pad_trailing(value, width, fill)

  defp pad(value, %__MODULE__{width: width, fill: fill, align: ?^}) do
    length = IO.iodata_length(value)
    length_half = length / 2
    prefix_length = ceil(length_half)
    suffix_length = floor(length_half)

    width_half = width / 2
    front_length = ceil(width_half)
    back_length = floor(width_half)

    front = String.duplicate(fill, max(0, front_length - prefix_length))
    back = String.duplicate(fill, max(0, back_length - suffix_length))

    [front, value, back]
  end
end
