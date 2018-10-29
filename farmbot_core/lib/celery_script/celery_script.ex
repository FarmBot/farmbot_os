defmodule Farmbot.Core.CeleryScript do
  @moduledoc """
  Helpers for executing CeleryScript.
  """
  def rpc_request(ast, fun) do
    Farmbot.CeleryScript.RunTime.rpc_request(Farmbot.CeleryScript.RunTime, ast, fun)
  end

  def sequence(%Farmbot.Asset.Sequence{} = seq, fun) do
    ast = Farmbot.CeleryScript.AST.decode(seq)
    Farmbot.CeleryScript.RunTime.sequence(Farmbot.CeleryScript.RunTime, ast, seq.id, fun)
  end
end
