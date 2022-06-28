defmodule Fmt.IO.Sigil do
  @moduledoc """
  This module provides `sigil_F/2` macro that generates formatting function
  out of the format string passed as the argument, ex.:

      iex> import #{inspect(__MODULE__)}
      iex> func = ~F(~.3f)
      iex> func.(3.14159)
      "3.142"

  For supported format check out `:io.fwrite/2`.
  """

  defp error(msg, caller) do
    raise CompileError,
      file: caller.file,
      line: caller.line,
      description: msg
  end

  defmacro sigil_F({:<<>>, _, [format]}, []) do
    amount = Fmt.IO.parse(format)
    args = Macro.generate_arguments(amount, __CALLER__.module)

    quote do
      fn unquote_splicing(args) ->
        unquote(Fmt.IO).format(unquote(format), [unquote_splicing(args)])
      end
    end
  catch
    :end -> error("Unexpected end of string", __CALLER__)
    {:unexpected, c} -> error("Unexpected character '#{<<c>>}'", __CALLER__)
  end

  defmacro sigil_F({:<<>>, _, [format]}, 'c') do
    amount = Fmt.IO.parse(format)
    args = Macro.generate_arguments(amount, __CALLER__.module)

    quote do
      fn unquote_splicing(args) ->
        unquote(Fmt.IO).format_iolist(unquote(format), [unquote_splicing(args)])
      end
    end
  catch
    :end -> error("Unexpected end of string", __CALLER__)
    {:unexpected, c} -> error("Unexpected character '#{<<c>>}'", __CALLER__)
  end
end
