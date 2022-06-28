defmodule Fmt.IO do
  @modifiers 'cfegswpWPBX#bx+i'

  def format(format, args) do
    format
    |> format_iolist(args)
    |> :erlang.iolist_to_binary()
  end

  def format_iolist(format, args) do
    format
    |> scan_inspect(args)
    |> :io_lib.build_text()
  end

  defp scan_inspect(format, args, opts \\ %Inspect.Opts{})

  defp scan_inspect(format, [], _opts) do
    :io_lib.scan_format(format, [])
  end

  defp scan_inspect(format, args, opts) do
    format
    |> :io_lib.scan_format(args)
    |> Enum.map(&handle_format_spec(&1, opts))
  end

  @inspected_format_spec %{
    adjust: :right,
    args: [],
    control_char: ?s,
    encoding: :unicode,
    pad_char: ?\s,
    precision: :none,
    strings: true,
    width: :none
  }

  defp handle_format_spec(%{control_char: char} = spec, opts) when char in 'wWpP' do
    %{args: args, width: width, strings: strings?} = spec

    opts = %{
      opts
      | charlists: inspect_charlists(strings?, opts),
        limit: inspect_limit(char, args, opts),
        width: inspect_width(char, width)
    }

    %{@inspected_format_spec | args: [inspect_data(args, opts)]}
  end

  defp handle_format_spec(spec, _opts), do: spec

  defp inspect_charlists(false, _), do: :as_lists
  defp inspect_charlists(_, opts), do: opts.charlists

  defp inspect_limit(char, [_, limit], _) when char in 'WP', do: limit
  defp inspect_limit(_, _, opts), do: opts.limit

  defp inspect_width(char, _) when char in 'wW', do: :infinity
  defp inspect_width(_, width), do: width

  defp inspect_data([data | _], opts) do
    width = if opts.width == :none, do: 80, else: opts.width

    data
    |> Inspect.Algebra.to_doc(opts)
    |> Inspect.Algebra.format(width)
  end

  @doc false
  def parse(format), do: parse(format, 0)

  @doc false
  def parse("", count), do: count

  def parse("~" <> rest, count) do
    {rest, sub_count} = parse_format(rest)

    parse(rest, count + sub_count)
  end

  def parse(<<_, rest::binary>>, count), do: parse(rest, count)

  defp parse_format(input), do: parse_format(input, 0, :width)

  defp parse_format("*" <> rest, count, :width),
    do: parse_format(rest, count + 1, :precision)

  defp parse_format(".*" <> rest, count, :width),
    do: parse_format(rest, count + 1, :pad)

  defp parse_format("." <> rest, count, :width),
    do: parse_format(rest, count, :precision)

  defp parse_format(".*" <> rest, count, :precision),
    do: parse_format(rest, count + 1, :pad)

  defp parse_format(".*" <> rest, count, :pad),
    do: parse_format(rest, count + 1, :specifier)

  defp parse_format(<<".", _, rest::binary>>, count, :pad),
    do: parse_format(rest, count, :specifier)

  defp parse_format(<<c, rest::binary>>, count, part)
       when part in ~w[precision width]a and c in ?0..?9 do
    parse_format(rest, count, part)
  end

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
