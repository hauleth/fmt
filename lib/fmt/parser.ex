defmodule Fmt.Parser do
  def parse(input), do: parse(input, [])

  defp parse("", acc), do: Enum.reverse(acc)
  defp parse(~S(\x) <> <<a, b>> <> rest, acc), do: parse(rest, [String.to_integer(<<a, b>>, 16) | acc])
  defp parse(<<?\\, c::utf8>> <> rest, acc), do: parse(rest, [escaped(c) | acc])
  defp parse(<<c::utf8>> <> rest, acc), do: parse(rest, [<<c>> | acc])

  defp escaped(?0), do: 0x00
  defp escaped(?a), do: ?\a
  defp escaped(?b), do: ?\b
  defp escaped(?t), do: ?\t
  defp escaped(?n), do: ?\n
  defp escaped(?v), do: ?\v
  defp escaped(?f), do: ?\f
  defp escaped(?r), do: ?\r
  defp escaped(?e), do: ?\e
end
