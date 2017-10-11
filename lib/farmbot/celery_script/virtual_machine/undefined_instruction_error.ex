defmodule Farmbot.CeleryScript.VirtualMachine.UndefinedInstructionError do
  @moduledoc "Undefined Instruction. Usually means something is not implemented."

  defexception [:message, :instruction]

  @doc false
  def exception(instruction) do
    instr = Macro.underscore(instruction)
    %__MODULE__{message: "Undefined instruction: #{instr}", instruction: instruction}
  end
end
