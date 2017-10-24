defmodule Farmbot.CeleryScript.VirtualMachine.Instruction.Calibrate do
  @moduledoc """
  calibrate
  """

  alias Farmbot.CeleryScript.AST
  alias Farmbot.CeleryScript.VirtualMachine.Instruction
  @behaviour Instruction

  def precompile(%AST{} = ast) do
    {:ok, ast}
  end

  def execute(args, body) do

  end
end
