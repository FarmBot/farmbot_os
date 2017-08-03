defimpl Farmbot.FarmEvent.Executer, for: Farmbot.Database.Syncable.Regimen do
  def execute_event(regimen, %Farmbot.Context{} = ctx, now) do
    case Process.whereis(:"regimen-#{regimen.id}") do
      nil -> {:ok, _pid} = Farmbot.Regimen.Supervisor.add_child(ctx, regimen, now)
      pid -> {:ok, pid}
    end
  end
end
