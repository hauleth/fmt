defmodule Fmt.SigilTest do
  use ExUnit.Case, async: true

  import Fmt.Sigil

  @subject Fmt.Sigil

  doctest @subject

  test "compilation fails on unsupported character" do
    quoted =
      quote do
        import unquote(@subject)

        ~F(~!)
      end

    assert_raise CompileError, fn ->
      Code.compile_quoted(quoted)
    end
  end

  test "compilation fails when format string is too short" do
    quoted =
      quote do
        import unquote(@subject)

        ~F(~)
      end

    assert_raise CompileError, fn ->
      Code.compile_quoted(quoted)
    end
  end

  test "works with unicode" do
    formatter = ~F(zażółć gęślą jaźń)

    assert "zażółć gęślą jaźń" == formatter.()
  end

  test "supports * in specifier" do
    formatter = ~F(~*B)

    assert "   42" == formatter.(5, 42)
  end

  test "supports * in n and ~ specifiers" do
    formatter = ~F(~*~)
    assert "~~~~~" == formatter.(5)

    formatter = ~F(~*n)
    assert "\n\n\n\n\n" == formatter.(5)
  end

  test "you can call generated function inline" do
    assert "3.142" == ~F(~.3f).(3.14159)
  end

  test "support * as different modifiers" do
    assert       "  255" == ~F(~*B).(5, 255)
    assert        "2010" == ~F(~.*B).(5, 255)
    assert       " 2010" == ~F(~5.*B).(5, 255)
    assert         "255" == ~F(~..*B).(5, 255)
    assert "\x05\x05255" == ~F(~5..*B).(5, 255)
    assert        "2010" == ~F(~.5.*B).(5, 255)
    assert    "\x052010" == ~F(~5.5.*B).(5, 255)
    assert       " 2010" == ~F(~*.*B).(5, 5, 255)
    assert    "\x052010" == ~F(~*.*.*B).(5, 5, 5, 255)
  end
end
