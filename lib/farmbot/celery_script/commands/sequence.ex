defmodule Farmbot.CeleryScript.Command.Sequence do
  @moduledoc """
    Sequence
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast

  @behaviour Command

  @doc ~s"""
    Executes a sequence. this one is non blocking and needs to disapear.
      args: %{},
      body: [Ast.t]
  """
  @spec run(%{}, [Ast.t]) :: no_return
  def run(args, body) do
    # rebuild the ast node
    ast = %Ast{kind: "sequence", args: args, body: body}
    {:ok, _pid} = Farmbot.SequenceRunner.start_link(ast)
    # Elixir.Sequence.Supervisor.add_child(ast, Timex.now())
  end
end
