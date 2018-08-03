defmodule Csvm.AST.UnslicerTest do
  use ExUnit.Case, async: true
  alias Csvm.AST.Unslicer

  test "unslices all the things" do
    heap = Csvm.TestSupport.Fixtures.heap()
    ast = Unslicer.run(heap, Address.new(1))
    assert ast.kind == :sequence

    assert ast.args == %{
             locals: %Csvm.AST{
               args: %{},
               body: [],
               comment: nil,
               kind: :scope_declaration
             },
             version: 20_180_209
           }

    assert Enum.at(ast.body, 0).kind == :move_absolute
    assert Enum.at(ast.body, 1).kind == :move_relative
    assert Enum.at(ast.body, 2).kind == :write_pin
    refute ast.comment
  end
end
