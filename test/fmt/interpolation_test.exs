defmodule Fmt.InterpolationTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @subject Fmt.Interpolation

  doctest @subject

  defp non_neg_integer() do
    gen(all int <- positive_integer(), do: int - 1)
  end

  defp integer_type do
    ~w[hex octal binary decimal]a
    |> Enum.map(&constant/1)
    |> one_of()
  end

  property "to_string" do
    input = @subject.build(value: {:ident, "val"})
    types = [atom(:alphanumeric), integer(), float(), string(:printable)]

    check all val <- one_of(types) do
      assert to_string(val) == eval(input, val: val)
    end
  end

  property "inspect" do
    input = @subject.build(value: {:ident, "val"}, type: :inspect)

    check all val <- term() do
      assert inspect(val, width: :infinity) == eval(input, val: val)
    end
  end

  property "pretty inspect" do
    input = @subject.build(value: {:ident, "val"}, alternate: true, type: :inspect)

    check all val <- term() do
      assert inspect(val, pretty: true, width: :infinity) == eval(input, val: val)
    end
  end

  describe "integer" do
    property "hex" do
      input = @subject.build(value: {:ident, "val"}, type: :hex)

      assert "0x0" == eval(input, val: 0)

      check all val <- positive_integer() do
        stringified = Integer.to_string(val, 16)
        assert "0x" <> stringified == eval(input, val: val)
        assert "-0x" <> stringified == eval(input, val: -val)
      end
    end

    property "decimal" do
      input = @subject.build(value: {:ident, "val"}, type: :decimal)

      assert "0" == eval(input, val: 0)

      check all val <- positive_integer() do
        stringified = Integer.to_string(val, 10)
        assert stringified == eval(input, val: val)
        assert "-" <> stringified == eval(input, val: -val)
      end
    end

    property "octal" do
      input = @subject.build(value: {:ident, "val"}, type: :octal)

      assert "0o0" == eval(input, val: 0)

      check all val <- positive_integer() do
        stringified = Integer.to_string(val, 8)
        assert "0o" <> stringified == eval(input, val: val)
        assert "-0o" <> stringified == eval(input, val: -val)
      end
    end

    property "binary" do
      input = @subject.build(value: {:ident, "val"}, type: :binary)

      assert "0b0" == eval(input, val: 0)

      check all val <- positive_integer() do
        stringified = Integer.to_string(val, 2)
        assert "0b" <> stringified == eval(input, val: val)
        assert "-0b" <> stringified == eval(input, val: -val)
      end
    end

    property "zero pad" do
      check all val <- integer(),
                width <- positive_integer(),
                type <- one_of([integer_type(), constant(nil)]) do
        input =
          @subject.build(
            value: {:ident, "val"},
            zero_pad: true,
            width: width,
            type: type
          )

        assert String.length(eval(input, val: val)) >= width
      end
    end

    property "force sign" do
      check all val <- positive_integer(),
                type <- one_of([integer_type(), constant(nil)]) do
        input =
          @subject.build(
            value: {:ident, "val"},
            sign: ?+,
            type: type
          )

        assert String.starts_with?(eval(input, val: val), "+")
        assert String.starts_with?(eval(input, val: -val), "-")
      end
    end
  end

  describe "right align" do
    test "is aligned" do
      input =
        @subject.build(
          value: {:ident, "val"},
          width: 10,
          type: nil
        )

      assert "       foo" == eval(input, val: "foo")
    end

    property "fixed" do
      check all val <- string(:ascii),
                width <- non_neg_integer() do
        input =
          @subject.build(
            value: {:ident, "val"},
            width: width,
            type: nil
          )

        assert String.length(eval(input, val: val)) >= width
      end
    end

    property "variable" do
      check all val <- string(:ascii),
                width <- non_neg_integer() do
        input =
          @subject.build(
            value: {:ident, "val"},
            width: {:ident, "width"},
            type: nil
          )

        assert String.length(eval(input, val: val, width: width)) >= width
      end
    end
  end

  describe "left align" do
    test "is aligned" do
      input =
        @subject.build(
          value: {:ident, "val"},
          align: ?<,
          width: 10,
          type: nil
        )

      assert "foo       " == eval(input, val: "foo")
    end

    property "fixed" do
      check all val <- string(:ascii),
                width <- non_neg_integer() do
        input =
          @subject.build(
            value: {:ident, "val"},
            align: ?<,
            width: width,
            type: nil
          )

        assert String.length(eval(input, val: val)) >= width
      end
    end

    property "variable" do
      check all val <- string(:ascii),
                width <- non_neg_integer() do
        input =
          @subject.build(
            value: {:ident, "val"},
            align: ?<,
            width: {:ident, "width"},
            type: nil
          )

        assert String.length(eval(input, val: val, width: width)) >= width
      end
    end
  end

  describe "center align" do
    test "is aligned" do
      input =
        @subject.build(
          value: {:ident, "val"},
          align: ?^,
          width: 11,
          type: nil
        )

      assert "    foo    " == eval(input, val: "foo")
    end

    property "fixed" do
      check all val <- string(:ascii),
                width <- non_neg_integer() do
        input =
          @subject.build(
            value: {:ident, "val"},
            align: ?^,
            width: width,
            type: nil
          )

        assert String.length(eval(input, val: val)) >= width
      end
    end

    property "variable" do
      check all val <- string(:ascii),
                width <- non_neg_integer() do
        input =
          @subject.build(
            value: {:ident, "val"},
            align: ?^,
            width: {:ident, "width"},
            type: nil
          )

        assert String.length(eval(input, val: val, width: width)) >= width
      end
    end
  end

  describe "float" do
    test "precision" do
      input =
        @subject.build(
          value: {:ident, "val"},
          precision: 2,
          type: nil
        )

      assert "123.46" == eval(input, val: 123.456)
    end
  end

  describe "binary" do
    test "hex" do
      input =
        @subject.build(
          value: {:ident, "val"},
          type: :hex
        )

      assert "<<0xDE, 0xAD, 0xBE, 0xEF>>" == eval(input, val: <<0xde, 0xad, 0xbe, 0xef>>)
    end

    test "octal" do
      input =
        @subject.build(
          value: {:ident, "val"},
          type: :hex
        )

      assert "<<0o76, 0o54, 0o32, 0o10>>" == eval(input, val: <<0o76, 0o54, 0o32, 0o10>>)
    end
  end

  defp custom_env do
    val = nil
    fill = nil
    width = 0
    precision = 0

    # Supress warnings
    _ = val
    _ = fill
    _ = width
    _ = precision

    __ENV__
  end

  defp eval(input, binds) do
    {value, _} = Code.eval_quoted(@subject.to_quoted(input, custom_env()), binds)

    IO.iodata_to_binary(value)
  end
end
