defmodule Farmbot.CeleryScript.VirtualMachine.Instruction.Execute do
  @moduledoc """
  execute
  """

  alias Farmbot.CeleryScript.AST
  alias Farmbot.CeleryScript.VirtualMachine.Instruction
  @behaviour Instruction

  def precompile(%AST{} = ast) do
    # require IEx; IEx.pry
    res = Farmbot.HTTP.get!("/api/sequences/#{ast.args.sequence_id}") |> Map.get(:body) |> Poison.decode! |> Farmbot.CeleryScript.AST.parse
    {:ok, res}
  end

  def execute(args, body) do

  end
end
