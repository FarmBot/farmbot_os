defmodule Farmbot.CeleryScript.Command.Sequence do
  @moduledoc """
    Sequence
  """

  alias      Farmbot.CeleryScript.{Ast, Command, Types}
  alias      Farmbot.Context
  require    Logger
  @behaviour Command

  @doc ~s"""
    Executes a sequence. this one is non blocking and needs to disapear.
      args: %{},
      body: [Types.ast]
  """
  @spec run(%{}, [Types.ast], Context.t) :: Context.t
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
      {^pid, %Context{} = ctx}  ->
        Logger.info "Sequence complete.", type: :success
        ctx
      {^pid, {:error, _reason}} ->
        Logger.error "Sequence completed with error. See log."
        old_context
    end
  end
end
