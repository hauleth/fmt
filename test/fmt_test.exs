defmodule FmtTest do
  use ExUnit.Case

  @subject Fmt

  doctest @subject

  import Fmt

  test "simple example" do
    foo = 1

    assert "1" == ~F"#{foo}"
  end
end
