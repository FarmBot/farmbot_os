defmodule PointerTest do
  use ExUnit.Case, async: true

  test "inspects a pointer" do
    ptr = Pointer.new(Address.new(1), Address.new(2))
    assert inspect(ptr) == "#Pointer<1, 2>"
  end
end
