defmodule Farmbot.CeleryScript.VirtualMachine.Instruction.SetUserEnv do
  @moduledoc """
  set_user_env
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
