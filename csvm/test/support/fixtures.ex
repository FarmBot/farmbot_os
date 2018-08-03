defmodule Csvm.TestSupport.Fixtures do
  def master_sequence do
    File.read!("fixture/master_sequence.term")
    |> :erlang.binary_to_term()
  end

  def heap do
    {:ok, map} = Csvm.TestSupport.Fixtures.master_sequence()
    ast = Csvm.AST.decode(map)
    Csvm.AST.Slicer.run(ast)
  end
end
