defmodule Farmbot.Target.Configurator.Validator do
  use GenServer
  require Logger
  import Farmbot.Config, only: [get_config_value: 3, update_config_value: 4]
  alias Farmbot.Target.Network
  import Farmbot.Target.Network.Utils
  alias Farmbot.Bootstrap.Authorization

  @steps [
    :ntp,
    :dns,
    :auth
  ]

  @checkup_time_ms 7000
  # 30 minutes
  @success_time_ms 1_800_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    {:ok, 0, 0}
  end

  def handle_info(:timeout, -1) do
    {:noreply, 0, 0}
  end

  def handle_info(:timeout, step_index) do
    case Enum.at(@steps, step_index) do
      :ntp -> check_ntp(step_index)
      :dns -> check_dns(step_index)
      :auth -> check_auth(step_index)
    end
  end

  def check_ntp(indx) do
    Logger.info("Checking for valid NTP")

    if Nerves.Time.synchronized?() do
      {:noreply, indx + 1, 0}
    else
      Nerves.Time.restart_ntpd()
      {:noreply, 0, @checkup_time_ms}
    end
  end

  def check_dns(indx) do
    Logger.info("Checking for valid DNS")

    case test_dns() do
      {:ok, _} -> {:noreply, indx + 1, 0}
      {:error, _} -> {:noreply, 0, @checkup_time_ms}
    end
  end

  def check_auth(_indx) do
    email = get_config_value(:string, "authorization", "email")
    password = get_config_value(:string, "authorization", "password")
    secret = get_config_value(:string, "authorization", "secret")
    server = get_config_value(:string, "authorization", "server")

    cond do
      email && password && server ->
        authorize_with_password(email, password, server)

      email && secret && server ->
        authorize_with_secret(email, secret, server)
    end
  end

  defp authorize_with_password(email, password, server) do
    with {:ok, {:RSAPublicKey, _, _} = rsa_key} <- Authorization.fetch_rsa_key(server),
         secret <- Authorization.build_secret(email, password, rsa_key),
         {:ok, payload} <- Authorization.build_payload(secret),
         {:ok, resp} <- Authorization.request_token(server, payload),
         {:ok, %{"token" => %{"encoded" => tkn}}} <- Farmbot.JSON.decode(resp) do
      update_config_value(:string, "authorization", "token", tkn)
      update_config_value(:string, "authorization", "secret", secret)
      update_config_value(:string, "authorization", "password", nil)
      Farmbot.Target.Network.hostap_down()
      Network.validate()
      {:noreply, -1, @success_time_ms}
    else
      error ->
        Logger.error("Authorization with password failure: #{inspect(error)}")
        {:noreply, 0, @checkup_time_ms}
    end
  end

  defp authorize_with_secret(_email, secret, server) do
    with {:ok, payload} <- Authorization.build_payload(secret),
         {:ok, resp} <- Authorization.request_token(server, payload),
         {:ok, %{"token" => %{"encoded" => tkn}}} <- Farmbot.JSON.decode(resp) do
      update_config_value(:string, "authorization", "token", tkn)
      update_config_value(:string, "authorization", "password", nil)
      Farmbot.Target.Network.hostap_down()
      Network.validate()
      {:noreply, -1, @success_time_ms}
    else
      error ->
        Logger.error("Authorization with secret failure: #{inspect(error)}")
        {:noreply, 0, @checkup_time_ms}
    end
  end
end
