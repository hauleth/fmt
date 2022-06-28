defmodule Fmt.Parser do
  import NimbleParsec
  import Fmt.Parser.Helpers

  defp escaped(?0), do: <<?\0>>
  defp escaped(?a), do: <<?\a>>
  defp escaped(?b), do: <<?\b>>
  defp escaped(?t), do: <<?\t>>
  defp escaped(?n), do: <<?\n>>
  defp escaped(?v), do: <<?\v>>
  defp escaped(?f), do: <<?\f>>
  defp escaped(?r), do: <<?\r>>
  defp escaped(?e), do: <<?\e>>
  defp escaped(c) when is_integer(c), do: <<c::utf8>>
  defp escaped({:hex, c}) when is_integer(c), do: <<c>>
  defp escaped({:unicode, c}) when is_integer(c), do: <<c::utf8>>

  ident =
    ascii_char([?a..?z, ?_])
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 0)
    |> optional(ascii_char([??, ?!]))
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:ident)
    |> label("identifier")

  sign = ascii_char('+-') |> tag(:sign)
  align = ascii_char('<^>') |> tag(:align)

  parameter = ident |> ignore(string("$"))

  count = choice([parameter, integer(min: 1)])

  width = unwrap_and_tag(count, :width)
  precision = unwrap_and_tag(count, :precision)

  fill = utf8_string([], 1) |> tag(:fill)

  # Types:
  #
  # - `?` - `Kernel.inspect/1`
  # - `!` - `Kernel.inspect(val, structs: false)`
  # - `x` - hexadecimal (downcase)
  # - `X` - hexadecimal (upcase)
  # - `o` - octal
  # - `b` - binary
  # - `d` - decimal
  # - `s` - `Kernel.to_string/1`
  type =
    %{
      "x" => :hex,
      "o" => :octal,
      "b" => :binary,
      "d" => :decimal,
      "?" => :inspect,
      "!" => :raw,
      "s" => nil
    }
    |> Enum.map(fn {s, t} -> replace(string(s), t) end)
    |> choice()
    |> unwrap_and_tag(:type)

  format_spec =
    choice([
      align,
      concat(fill, align),
      empty()
    ])
    |> optional(sign)
    |> optional(string("#") |> replace({:alternate, true}))
    |> optional(string("0") |> replace({:zero_pad, true}))
    |> optional(width)
    |> optional(concat(ignore(string(".")), precision))
    |> concat(type)

  separator = ows() |> string("::") |> ows() |> ignore()

  format_string =
    ows()
    |> concat(ident)
    |> unwrap_and_tag(:value)
    |> optional(concat(separator, format_spec))
    |> ows()

  # defparsec(:format_string, format_string, inline: true, export_metadata: true)

  escape =
    ignore(string("\\"))
    |> choice([
      ignore(string("u")) |> hex_int(4) |> unwrap_and_tag(:unicode),
      ignore(string("x")) |> hex_int(2) |> unwrap_and_tag(:hex),
      utf8_char(not: ?u, not: ?x)
    ])
    |> map({:escaped, []})

  # defparsec(:escape, escape, inline: true, export_metadata: true)

  str = lookahead_not(string("\#{")) |> utf8_char(not: ?\\)

  interpolation =
    ignore(string("\#{"))
    |> tag(lookahead_not(string("}")) |> concat(format_string), :eval)
    |> ignore(string("}"))

  full =
    repeat(
      choice([
        interpolation,
        escape,
        str
      ])
    )
    |> eos()
    |> reduce({:reductor, [[""]]})

  defparsecp(:do_parse, full, inline: true, export_metadata: true)

  defp reductor([], result), do: Enum.reverse(result)

  defp reductor([x | xs], [y | ys]) when is_integer(x) do
    reductor(xs, [y <> <<x::utf8>> | ys])
  end

  defp reductor([x | xs], [y | ys]) when is_binary(x) do
    reductor(xs, [y <> x | ys])
  end

  defp reductor([{:eval, opts} | xs], ys) do
    reductor(xs, ["", Fmt.Interpolation.build(opts) | ys])
  end

  def parse(input) do
    case do_parse(input) do
      {:ok, [parsed], "", _, _, _} ->
        {:ok, parsed}

      {:error, _, _, _, _, _} = err ->
        err
    end
  end
end
