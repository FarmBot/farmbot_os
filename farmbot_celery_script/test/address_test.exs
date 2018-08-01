defmodule AddressTest do
  use ExUnit.Case, async: true

  test "inspect gives nice stuff" do
    assert inspect(Address.new(100)) == "#Address<100>"
  end

  test "increments an address" do
    base = Address.new(123)
    assert Address.inc(base) == Address.new(124)
  end

  test "decrements an address" do
    base = Address.new(123)
    assert Address.dec(base) == Address.new(122)
  end
end
