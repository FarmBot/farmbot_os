# These are sample instructions and implementations.
# They are not actual commands that will work tho. This is tested elsewhere.
defmodule SomeInstr do
  @moduledoc "Some instruction"
end

defmodule SomeImpl do
  @moduledoc "Some implementation for SomeImpl"
  def eval(_), do: :ok
end

defmodule SomeOtherInstr do
  @moduledoc "Some other instruction"
end

defmodule SomeOtherImpl do
  @moduledoc "Some other implementation"
  def eval(_), do: :ok
end

defmodule HalfImpl do
  @moduledoc "exists but doesnt implement"
end

defmodule Farmbot.CeleryScript.VirtualMachine.InstructionSetTest do
  @moduledoc "test the 'compiler' for the parts of CeleryScript."

  use ExUnit.Case
  alias Farmbot.CeleryScript.VirtualMachine.InstructionSet
  alias Farmbot.CeleryScript.VirtualMachine.UndefinedInstructionError

  test "implements squarebracket access" do
    is = %InstructionSet{instructions: %{SomeInstr => SomeImpl}}
    assert is[SomeInstr] == SomeImpl
  end

  test "squarebracket access raises if there is no implemetation" do
    is = %InstructionSet{}

    assert_raise UndefinedInstructionError, "Undefined instruction: some_cool_instr", fn ->
      is[SomeCoolInstr]
    end
  end

  test "builds new instruction sets" do
    is =
      InstructionSet.new()
      |> InstructionSet.impl(SomeInstr, SomeImpl)
      |> InstructionSet.impl(SomeOtherInstr, SomeOtherImpl)

    assert is[SomeInstr] == SomeImpl
    assert is[SomeOtherInstr] == SomeOtherImpl
  end

  test "raises when trying to implement a instruction with no code." do
    is = InstructionSet.new()

    assert_raise CompileError, " Failed to load implementation: some_cool_impl.", fn ->
      is
      |> InstructionSet.impl(SomeCoolInstr, SomeCoolImpl)
    end
  end

  test "raises when the module exists but does not implement CeleryScript." do
    is = InstructionSet.new()

    assert_raise CompileError, " half_impl does not implement CeleryScript.", fn ->
      is |> InstructionSet.impl(SomeCoolInstr, HalfImpl)
    end
  end

  test "ensures we have default implementation" do
    is = %InstructionSet{}
    assert is[Calibrate]
    assert is[CheckUpdates]
    assert is[ConfigUpdate]
    assert is[Coordinate]
    assert is[DataUpdate]
    assert is[EmergencyLock]
    assert is[EmergencyUnlock]
    assert is[Execute]
    assert is[ExecuteScript]
    assert is[Explanation]
    assert is[FactoryReset]
    assert is[FindHome]
    assert is[Home]
    assert is[InstallFarmware]
    assert is[MoveAbsolute]
    assert is[MoveRelative]
    assert is[Nothing]
    assert is[Pair]
    assert is[ReadAllParams]
    assert is[PowerOff]
    assert is[ReadParam]
    assert is[ReadPin]
    assert is[ReadStatus]
    assert is[Reboot]
    assert is[RemoveFarmware]
    assert is[RpcError]
    assert is[RpcRequest]
    assert is[RpcOk]
    assert is[SendMessage]
    assert is[Sequence]
    assert is[SetUserEnv]
    assert is[Sync]
    assert is[TakePhoto]
    assert is[TogglePin]
    assert is[UpdateFarmware]
    assert is[Wait]
    assert is[WritePin]
    assert is[Zero]
  end
end
