defimpl Farmbot.FarmEvent.Executer, for: Farmbot.Database.Syncable.Regimen do
  def execute_event(regimen, %Farmbot.Context{} = ctx, now) do
    {:ok, _pid} = Farmbot.Regimen.Supervisor.add_child(ctx, regimen, now)
  end
end
