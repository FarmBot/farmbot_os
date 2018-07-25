defmodule Farmbot.CeleryScript do
  def to_ast(data) do
    Csvm.AST.decode(data)
  end

  def execute_sequence(%Farmbot.Asset.Sequence{} = seq) do
    schedule_sequence(seq)
    |> await_sequence()
  end

  def schedule_sequence(%Farmbot.Asset.Sequence{} = seq) do
    Csvm.queue(seq, seq.id)
  end

  def await_sequence(ref) do
    Csvm.await(ref)
  end
end
