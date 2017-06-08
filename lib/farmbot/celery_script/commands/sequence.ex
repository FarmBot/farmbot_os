defmodule Farmbot.CeleryScript.Command.Sequence do
  @moduledoc """
    Sequence
  """

  alias Farmbot.CeleryScript.{Command, Ast}
  alias Farmbot.Context
  require Logger

  @behaviour Command

  @doc ~s"""
    Executes a sequence. this one is non blocking and needs to disapear.
      args: %{},
      body: [Ast.t]
  """
  @spec run(%{}, [Ast.t], Context.t) :: Context.t
  def run(args, body, %Context{} = context) do
    # rebuild the ast node
    ast          = %Ast{kind: "sequence", args: args, body: body}
    # Logger.debug "Starting sequence: #{inspect ast}"
    {:ok, pid}   = Farmbot.Sequence.Manager.start_link(context, ast, self())
    next_context = wait_for_sequence(pid, context)
    next_context
  end

  @spec wait_for_sequence(pid, Context.t) :: Context.t
  defp wait_for_sequence(pid, old_context) do
    receive do
      {^pid, %Context{} = ctx} -> ctx
      {^pid, {:error, _reason}} -> old_context
    end
  end
end
