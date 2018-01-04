defmodule Farmbot.System.UpdateTimer do
  @moduledoc false

  @twelve_hours 4.32e+7 |> round()
  use GenServer
  use Farmbot.Logger

  def wait_for_http(callback) do
    case Process.whereis(Farmbot.HTTP) do
      nil ->
        Process.sleep(1000)
        wait_for_http(callback)
      pid when is_pid(pid) ->
        Process.send_after(callback, :checkup, 2000)
    end
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def terminate(reason, _) do
    Logger.error 1, "Failed to check updates: #{inspect reason}"
  end

  def init([]) do
    spawn __MODULE__, :wait_for_http, [self()]
    {:ok, [], :hibernate}
  end

  def handle_info(:checkup, state) do
    osau = Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "os_auto_update")
    Farmbot.System.Updates.check_updates(osau)
    Process.send_after(self(), :checkup, @twelve_hours)
    {:noreply, state, :hibernate}
  end
end
