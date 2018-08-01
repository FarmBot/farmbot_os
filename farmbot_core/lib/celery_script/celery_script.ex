defmodule Farmbot.Core.CeleryScript do
  @moduledoc """
  Helpers for executing CeleryScript.
  """
  def rpc_request(data, fun) do
    Farmbot.CeleryScript.RunTime.rpc_request(Farmbot.CeleryScript.RunTime, data, fun)
  end

  def sequence(%Farmbot.Asset.Sequence{} = seq, fun) do
    Farmbot.CeleryScript.RunTime.sequence(Csvm, seq, seq.id, fun)
  end
end
