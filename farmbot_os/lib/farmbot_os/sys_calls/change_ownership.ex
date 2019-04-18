defmodule FarmbotOS.SysCalls.ChangeOwnership do
  @moduledoc false
  require Logger
  require FarmbotCore.Logger
  import FarmbotCore.Config, only: [get_config_value: 3, update_config_value: 4]
  alias FarmbotCore.{Asset, EctoMigrator}
  alias FarmbotExt.Bootstrap.Authorization

  def restart do
    Logger.info("Stopping app: :farmbot")
    _ = Application.stop(:farmbot)

    Logger.info("Stopping app: :farmbot_ext")
    _ = Application.stop(:farmbot_ext)

    Logger.info("Stopping app: :farmbot_core")
    _ = Application.stop(:farmbot_core)

    Logger.info("Starting ap: :farmbot_core")
    _ = Application.ensure_all_started(:farmbot_core)

    Logger.info("Starting ap: :farmbot_ext")
    _ = Application.ensure_all_started(:farmbot_ext)

    Logger.info("Starting ap: :farmbot")
    _ = Application.ensure_all_started(:farmbot)
  end

  def change_ownership(email, secret, server) do
    server = server || get_config_value(:string, "authorization", "server")

    case Authorization.authorize_with_secret(email, secret, server) do
      {:ok, _token} ->
        FarmbotCore.Logger.warn(1, "Farmbot is changing ownership to #{email} - #{server}")
        :ok = replace_credentials(email, secret, server)
        _ = clean_assets()
        _ = clean_farmwares()
        FarmbotCore.Logger.warn(1, "Going down for reboot")
        Supervisor.start_child(:elixir_sup, {Task, &restart/0})
        :ok

      {:error, _} ->
        FarmbotCore.Logger.error(1, "Invalid credentials for change ownership")
        {:error, "Invalid credentials for change ownership"}
    end
  end

  defp clean_assets do
    EctoMigrator.drop(Asset.Repo)
    :ok
  end

  defp clean_farmwares do
    :ok
  end

  defp replace_credentials(email, secret, server) do
    FarmbotCore.Logger.debug(3, "Replacing credentials")
    update_config_value(:string, "authorization", "password", nil)
    update_config_value(:string, "authorization", "token", nil)
    update_config_value(:string, "authorization", "email", email)
    update_config_value(:string, "authorization", "server", server)
    update_config_value(:string, "authorization", "secret", secret)
    :ok
  end
end
