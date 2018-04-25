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
    Farmbot.System.Registry.subscribe(self())
    {:ok, []}
  end

  def handle_info(:checkup, state) do
    osau = Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "os_auto_update")
    case Farmbot.System.Updates.check_updates() do
      {:error, err} -> Logger.error 1, "Error checking for updates: #{inspect err}"
      nil -> Logger.debug 3, "No updates available as of #{inspect Timex.now()}"
      url -> if osau, do: Farmbot.System.Updates.download_and_apply_update(url)
    end
    Process.send_after(self(), :checkup, @twelve_hours)
    {:noreply, state}
  end

  def handle_info({Farmbot.System.Registry, {:config_storage, {"settings", "beta_opt_in", true}}}, state) do
    if Process.whereis(Farmbot.Bootstrap.AuthTask) do
      Logger.debug 3, "Opted into beta updates. Refreshing token."
      Farmbot.Bootstrap.AuthTask.force_refresh()
    end
    {:noreply, state}
  end

  def handle_info({Farmbot.System.Registry, _info}, state) do
    {:noreply, state}
  end
end
