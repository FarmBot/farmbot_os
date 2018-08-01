defmodule Farmbot.CeleryScript.RunTime.TestSupport.Fixtures do
  @moduledoc false
  def master_sequence do
    File.read!("fixture/master_sequence.term")
    |> :erlang.binary_to_term()
  end

  def heap do
    {:ok, map} = Farmbot.CeleryScript.RunTime.TestSupport.Fixtures.master_sequence()
    ast = Farmbot.CeleryScript.AST.decode(map)
    Farmbot.CeleryScript.AST.Slicer.run(ast)
  end
end
