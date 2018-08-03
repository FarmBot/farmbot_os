defmodule Csvm.UtilsTest do
  use ExUnit.Case, async: true
  alias Csvm.Utils

  test "new pointer utility" do
    assert match?(%Pointer{}, Utils.ptr(1, 100))
    assert Utils.ptr(100, 50).heap_address == Address.new(50)
    assert Utils.ptr(99, 20).page_address == Address.new(99)
    assert inspect(Utils.ptr(20, 20)) == "#Pointer<20, 20>"
  end

  test "new ast utility" do
    alias Csvm.AST
    assert match?(%AST{}, Utils.ast(:action, %{a: 1}, []))
    assert match?(%AST{}, Utils.ast(:explode, %{a: 2}))
    assert Utils.ast(:drink, %{}, []) == AST.new(:drink, %{}, [])
  end

  test "new address utility" do
    assert match?(%Address{}, Utils.addr(100))
    assert Utils.addr(4000) == Address.new(4000)
  end
end
