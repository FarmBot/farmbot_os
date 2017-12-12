defmodule Farmbot.Bootstrap.AuthTask do
  @moduledoc "Background worker that refreshes a token every 30 minutes."
  use GenServer
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage

  # 30 minutes.
  @refresh_time 1.8e+6 |> round()

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    timer = Process.send_after(self(), :refresh, @refresh_time)
    {:ok, timer, :hibernate}
  end

  def handle_info(:refresh, _old_timer) do
    auth_task = Application.get_env(:farmbot, :behaviour)[:authorization]
    {email, pass, server} = {fetch_email(), fetch_pass(), fetch_server()}
    # Logger.busy(3, "refreshing token: #{auth_task} - #{email} - #{server}")
    Farmbot.System.GPIO.Leds.led_status_err()
    case auth_task.authorize(email, pass, server) do
      {:ok, token} ->
        # Logger.success(3, "Successful authorization: #{auth_task} - #{email} - #{server}")
        ConfigStorage.update_config_value(:bool, "settings", "first_boot", false)
        ConfigStorage.update_config_value(:string, "authorization", "token", token)
        Farmbot.System.GPIO.Leds.led_status_ok()
        restart_transports()
        refresh_timer(self())
      {:error, reason} ->
        Logger.error(1, "Token failed to reauthorize: #{auth_task} - #{email} - #{server} #{inspect reason}")
        refresh_timer(self())
    end
  end

  defp restart_transports do
    :ok = Supervisor.terminate_child(Farmbot.Bootstrap.Supervisor, Farmbot.BotState.Transport.Supervisor)
    case Supervisor.restart_child(Farmbot.Bootstrap.Supervisor, Farmbot.BotState.Transport.Supervisor) do
      {:ok, _} -> :ok
      {:error, :running} -> :ok
      {:error, {:already_started, _}} -> :ok
      err -> exit(err)
    end
  end

  defp refresh_timer(pid) do
    timer = Process.send_after(pid, :refresh, @refresh_time)
    {:noreply, timer, :hibernate}
  end

  defp fetch_email do
    ConfigStorage.get_config_value(:string, "authorization", "email") ||
      raise "No email provided."
  end

  defp fetch_pass do
    ConfigStorage.get_config_value(:string, "authorization", "password") ||
      raise "No password provided."
  end

  defp fetch_server do
    ConfigStorage.get_config_value(:string, "authorization", "server") ||
      raise "No server provided."
  end
end
