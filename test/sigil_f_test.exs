defmodule SigilFTest do
  use ExUnit.Case, async: true

  import SigilF

  @subject SigilF

  doctest @subject

  test "compilation fails on unsupported character" do
    quoted =
      quote do
        import unquote(@subject)

        ~f(~!)
      end

    assert_raise CompileError, fn ->
      Code.compile_quoted(quoted)
    end
  end

  test "compilation fails when format string is too short" do
    quoted =
      quote do
        import unquote(@subject)

        ~f(~)
      end

    assert_raise CompileError, fn ->
      Code.compile_quoted(quoted)
    end
  end

  test "works with unicode" do
    formatter = ~f(zażółć gęślą jaźń)

    assert "zażółć gęślą jaźń" == formatter.()
  end

  test "supports * in specifier" do
    formatter = ~f(~*B)

    assert "   42" == formatter.(5, 42)
  end

  test "supports * in n and ~ specifiers" do
    formatter = ~f(~*~)
    assert "~~~~~" == formatter.(5)

    formatter = ~f(~*n)
    assert "\n\n\n\n\n" == formatter.(5)
  end

  test "you can call generated function inline" do
    assert "3.142" == ~f(~.3f).(3.14159)
  end
end
