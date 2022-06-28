defmodule Fmt.Parser.Helpers do
  @moduledoc false

  import NimbleParsec

  def ows(combinator \\ empty()) do
    combinator |> ignore(ascii_string(' \t\n', min: 0))
  end

  def hex_int(combinator \\ empty(), size) do
    combinator
    |> label(
      map(
        ascii_string([?0..?9, ?a..?f, ?A..?F], size),
        {String, :to_integer, [16]}
      ),
      "hexadecimal integer"
    )
  end
end
