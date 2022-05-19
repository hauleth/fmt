defmodule Fmt do
  defmacro format(fmt) when is_binary(fmt) do
    fmt
  end

  defmacro sigil_f({:<<>>, _, [fmt]}, _) do
    IO.inspect(Fmt.Parser.parse(fmt))

    fmt
  end
end
