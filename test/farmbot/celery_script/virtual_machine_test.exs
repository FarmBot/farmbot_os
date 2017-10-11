defmodule Farmbot.VirtualMachineTest do
  @moduledoc """
  Test Virtual Machine implementation.
  This does not test each `instruction`.
  """

  use ExUnit.Case

  alias Farmbot.CeleryScript.{Ast, VirtualMachine}

  # alias VirtualMachine.RuntimeError, as: VmError
  # alias VirtualMachine.InstructionSet
  alias VirtualMachine.UndefinedInstructionError

  # Helper to build an ast node.
  defp build_ast(kind, args \\ %{}, body \\ []) do
    %Ast{kind: kind, args: args, body: body}
  end

  test "raises on unknown instruction" do
    kind = "do_a_barrel_roll"
    ast = build_ast(kind)

    assert_raise UndefinedInstructionError, "Undefined instruction: #{kind}", fn ->
      VirtualMachine.step(%VirtualMachine{running: true, program: [ast]})
    end
  end

  test "doesn't step when `running: false`" do
    vm = %VirtualMachine{running: false, program: []}
    new = VirtualMachine.step(vm)
    assert vm == new
  end

  test "shuts down machine when program is empty." do
    vm = %VirtualMachine{running: true, program: []}
    new = VirtualMachine.step(vm)
    assert new.running == false
  end
end
