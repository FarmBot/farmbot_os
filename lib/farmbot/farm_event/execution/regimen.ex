defimpl Farmbot.FarmEvent.Execution, for: Farmbot.Repo.Regimen do

  def execute_event(regimen, now) do
    case Process.whereis(:"regimen-#{regimen.id}") do
      nil -> {:ok, _pid} = Farmbot.Regimen.Supervisor.add_child(regimen, now)
      pid -> {:ok, pid}
    end
  end

end
