defimpl Farmbot.FarmEvent.Execution, for: Farmbot.Asset.Regimen do
  import Farmbot.Regimen.NameProvider

  def execute_event(regimen, now) do
    name = via(regimen)
    case GenServer.whereis(name) do
      nil -> {:ok, _pid} = Farmbot.Regimen.Supervisor.add_child(regimen, now)
      pid -> {:ok, pid}
    end
  end

end
