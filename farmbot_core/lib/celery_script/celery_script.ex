defmodule Farmbot.CeleryScript do
  def to_ast(data) do
    Csvm.AST.decode(data)
  end

  def execute_sequence(%Farmbot.Asset.Sequence{} = seq) do
    :ok
  end

  def schedule_sequence(%Farmbot.Asset.Sequence{} = seq) do
    :ok
  end

  def await_sequence(ref) do
    :ok
  end
end
