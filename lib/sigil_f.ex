defmodule SigilF do
  @moduledoc """
  This module provides `sigil_f/2` macro that generates formatting function
  out of the format string passed as the argument, ex.:

      iex> import SigilF
      iex> func = ~f(~.3f)
      iex> func.(3.14159)
      "3.142"

  For supported format check out `:io.fwrite/2`.
  """

  @modifiers 'cfegswpWPBX#bx+i'

  defp error(msg, caller) do
    raise CompileError,
      file: caller.file,
      line: caller.line,
      description: msg
  end

  defmacro sigil_f({:<<>>, _, [format]}, []) do
    amount = parse(format)
    args = Macro.generate_arguments(amount, __CALLER__.module)

    quote do
      fn unquote_splicing(args) ->
        :binary.list_to_bin(:io_lib.format(unquote(format), [unquote_splicing(args)]))
      end
    end
  catch
    :end -> error("Unexpected end of string", __CALLER__)
    {:unexpected, c} -> error("Unexpected character '#{<<c>>}'", __CALLER__)
  end

  defmacro sigil_f({:<<>>, _, [format]}, 'c') do
    amount = parse(format)
    args = Macro.generate_arguments(amount, __CALLER__.module)

    quote do
      fn unquote_splicing(args) ->
        :io_lib.format(unquote(format), [unquote_splicing(args)])
      end
    end
  catch
    :end -> error("Unexpected end of string", __CALLER__)
    {:unexpected, c} -> error("Unexpected character '#{<<c>>}'", __CALLER__)
  end

  defp parse(format), do: parse(format, 0)

  defp parse("", count), do: count

  defp parse("~" <> rest, count) do
    {rest, sub_count} = parse_format(rest)

    parse(rest, count + sub_count)
  end

  defp parse(<<_, rest::binary>>, count), do: parse(rest, count)

  defp parse_format(input), do: parse_format(input, 0, :width)

  defp parse_format("." <> rest, count, :precision),
    do: parse_format(rest, count, :precision)

  defp parse_format("*" <> rest, count, :width),
    do: parse_format(rest, count + 1, :precision)

  defp parse_format("*" <> rest, count, :precision),
    do: parse_format(rest, count + 1, :pad)

  defp parse_format(".*" <> rest, count, :pad),
    do: parse_format(rest, count + 1, :specifier)

  defp parse_format(<<".", _, rest::binary>>, count, :pad),
    do: parse_format(rest, count, :specifier)

  defp parse_format(<<c, rest::binary>>, count, part)
       when part in ~w[precision width]a and c in ?0..?9 do
    parse_format(rest, count, part)
  end

  defp parse_format(<<".", _::binary>> = rest, count, :width),
    do: parse_format(rest, count, :precision)

  # Match specifiers
  defp parse_format("tp" <> rest, count, _), do: {rest, count + 1}
  defp parse_format("lp" <> rest, count, _), do: {rest, count + 1}
  defp parse_format("tP" <> rest, count, _), do: {rest, count + 1}
  defp parse_format("lP" <> rest, count, _), do: {rest, count + 1}
  defp parse_format("~" <> rest, count, _), do: {rest, count}
  defp parse_format("n" <> rest, count, _), do: {rest, count}
  defp parse_format(<<c, rest::binary>>, count, _) when c in @modifiers, do: {rest, count + 1}

  defp parse_format("", _, _), do: throw(:end)
  defp parse_format(<<c, _::binary>>, _, _), do: throw({:unexpected, c})
end
