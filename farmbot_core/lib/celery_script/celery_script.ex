defmodule Farmbot.CeleryScript do
  def rpc_request(data, fun) do
    Csvm.rpc_request(Csvm, data, fun)
  end

  def sequence(%Farmbot.Asset.Sequence{} = seq, fun) do
    Csvm.sequence(Csvm, seq, seq.id, fun)
  end
end
