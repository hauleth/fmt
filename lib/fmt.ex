defmodule Fmt do
  defmacro sigil_F({:<<>>, _, [fmt]}, []) do
    output = build(fmt, __CALLER__)

    quote do
      IO.iodata_to_binary(unquote(output))
    end
  end

  defp build(input, env) do
    {:ok, parsed} = Fmt.Parser.parse(input)

    Enum.map(parsed, fn
      %Fmt.Interpolation{} = int -> Fmt.Interpolation.to_quoted(int, env)
      other -> other
    end)
  end
end
