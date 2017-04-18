defmodule Farmbot.CeleryScript.Command.Sequence do
  @moduledoc """
    Sequence
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast
  require Logger

  @behaviour Command

  @doc ~s"""
    Executes a sequence. this one is non blocking and needs to disapear.
      args: %{},
      body: [Ast.t]
  """
  @spec run(%{}, [Ast.t]) :: no_return
  def run(args, body) do
    # IO.inspect args
    # IO.inspect body
    # rebuild the ast node
    ast = %Ast{kind: "sequence", args: args, body: body}
    # Logger.debug "Starting sequence: #{inspect ast}"
    {:ok, pid} = Farmbot.SequenceRunner.start_link(ast)
    Farmbot.SequenceRunner.wait(pid)
  end
end
