defimpl Farmbot.FarmEvent.Executer, for: Farmbot.Database.Syncable.Sequence do
  alias Farmbot.Context
  def execute_event(sequence, %Context{} = ctx, _now) do
    sequence
    |> Farmbot.CeleryScript.Ast.parse()
    |> Farmbot.CeleryScript.Command.do_command(ctx)
  end
end
