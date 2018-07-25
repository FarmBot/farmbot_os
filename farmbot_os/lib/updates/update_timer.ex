defmodule Farmbot.System.UpdateTimer do
  @moduledoc false

  @twelve_hours 4.32e+7 |> round()
  use GenServer
  require Farmbot.Logger
  import Farmbot.Config, only: [get_config_value: 3]

  def wait_for_http(callback) do
    case Process.whereis(Farmbot.HTTP) do
      nil ->
        Process.sleep(1000)
        wait_for_http(callback)
      pid when is_pid(pid) ->
        do_check()
        Process.send_after(callback, :checkup, @twelve_hours)
    end
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def terminate(reason, _) do
    Farmbot.Logger.error 1, "Failed to check updates: #{inspect reason}"
  end

  def init([]) do
    spawn __MODULE__, :wait_for_http, [self()]
    Farmbot.Registry.subscribe()
    {:ok, []}
  end

  def handle_info(:checkup, state) do
    do_check()
    Process.send_after(self(), :checkup, @twelve_hours)
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, {Farmbot.Config, {"settings", "beta_opt_in", true}}}, state) do
    if Process.whereis(Farmbot.Bootstrap.AuthTask) do
      Farmbot.Logger.debug 3, "Opted into beta updates. Refreshing token."
      Farmbot.Bootstrap.AuthTask.force_refresh()
    end
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, _info}, state) do
    {:noreply, state}
  end

  defp do_check do
    osau = get_config_value(:bool, "settings", "os_auto_update")
    case Farmbot.System.Updates.check_updates() do
      {:error, err} -> Farmbot.Logger.error 1, "Error checking for updates: #{inspect err}"
      nil -> Farmbot.Logger.debug 3, "No updates available as of #{inspect Timex.now()}"
      url -> if osau, do: Farmbot.System.Updates.download_and_apply_update(url)
    end
  end
end
