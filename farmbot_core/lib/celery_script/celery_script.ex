defmodule Farmbot.Core.CeleryScript do
  @moduledoc """
  Helpers for executing CeleryScript.
  """

  alias Farmbot.CeleryScript.{RunTime, AST}

  @doc "Execute an RPC request"
  def rpc_request(ast, fun) do
    RunTime.rpc_request(RunTime, ast, fun)
  end

  @doc "Execute a Sequence"
  def sequence(%Farmbot.Asset.Sequence{} = seq, fun) do
    RunTime.sequence(RunTime, AST.decode(seq), seq.id, fun)
  end
end
