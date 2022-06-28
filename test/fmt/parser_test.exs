defmodule Fmt.ParserTest do
  use ExUnit.Case

  @subject Fmt.Parser

  doctest @subject

  # Test sigil to simplify the test declarations.
  #
  # It is equivalent of doing:
  #
  #     @subject.parse(~S(input))
  #
  defmacrop sigil_P({:<<>>, _, [input]}, _) do
    quote do
      @subject.parse(unquote(input))
    end
  end

  test "simple input" do
    assert {:ok, [""]} == ~P""
    assert {:ok, ["foo"]} == ~P"foo"
  end

  test "escaped" do
    assert {:ok, ["\#{}"]} == ~P"\#{}"
    assert {:ok, ["\0"]} == ~P"\0"
    assert {:ok, ["\a"]} == ~P"\a"
    assert {:ok, ["\b"]} == ~P"\b"
    assert {:ok, ["\t"]} == ~P"\t"
    assert {:ok, ["\n"]} == ~P"\n"
    assert {:ok, ["\v"]} == ~P"\v"
    assert {:ok, ["\f"]} == ~P"\f"
    assert {:ok, ["\r"]} == ~P"\r"
    assert {:ok, ["\e"]} == ~P"\e"
    assert {:ok, ["\""]} == ~P"\""
    assert {:ok, ["\""]} == ~P[\"]
    assert {:ok, ["\["]} == ~P'\['
  end

  test "hexadecimal" do
    assert {:ok, ["foo\xFF"]} == ~P"foo\xff"
    assert {:ok, ["foo\xFF"]} == ~P"foo\xFf"
    assert {:ok, ["foo\xFF"]} == ~P"foo\xfF"
    assert {:ok, ["foo\xFF"]} == ~P"foo\xFF"
  end

  test "unicode" do
    assert {:ok, ["\0"]} == ~P"\u0000"
    assert {:ok, ["ą"]} == ~P"\u0105"
    assert {:ok, ["ą"]} == ~P"ą"
    assert {:ok, ["ą"]} == ~P"\ą"
  end

  test "interpolation" do
    assert {:ok, ["", %Fmt.Interpolation{type: nil}, ""]} = ~P"#{foo}"
    assert {:ok, ["", %Fmt.Interpolation{type: :hex}, ""]} = ~P"#{foo::x}"
  end

  test "invalid" do
    assert {:error, _, _, _, _, _} = ~P"\x1"
    assert {:error, _, _, _, _, _} = ~P"\u1"
    assert {:error, _, _, _, _, _} = ~P"#{f"
    assert {:error, _, _, _, _, _} = ~P"#{f::}"
  end
end
