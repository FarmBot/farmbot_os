defmodule Farmbot.CeleryScript.AST.Node.ChangeOwnership do
  @moduledoc false

  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [update_config_value: 4, get_config_value: 3]
  use Farmbot.Logger

  allow_args []

  def execute(_, pairs, env) do
    env      = mutate_env(env)
    pair_map = pair_to_map(pairs)
    email    = pair_map["email"]
    secret   = pair_map["secret"] |> Base.decode64!(padding: false, ignore: :whitespace)
    server   = pair_map["server"] || get_config_value(:string, "authorization", "server")
    case test_credentials(email, secret, server) do
      {:ok, _token} ->
        Logger.warn 1, "Farmbot is changing ownership to #{email} - #{server}."
        Farmbot.BotState.set_sync_status(:maintenance)

        replace_credentials(email, secret, server)
        clean_assets()
        clean_farmwares()

        Logger.debug 1, "Going down for reboot."
        Farmbot.System.reboot("Change ownership")
        {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp replace_credentials(email, secret, server) do
    Logger.debug 3, "Replacing credentials."
    # Make sure to disable factory resetting otherwise we get a reboot loop.
    update_config_value(:bool, "settings", "disable_factory_reset", false)
    update_config_value(:string, "authorization", "email", email)
    update_config_value(:string, "authorization", "server", server)
    update_config_value(:string, "authorization", "password", secret)
    update_config_value(:string, "authorization", "token", nil)
    :ok
  end

  defp clean_assets do
    Logger.debug 3, "Cleaning assets."
    Farmbot.Asset.clear_all_data()
  end

  defp clean_farmwares do
    Logger.debug 3, "Cleaning Farmwares."
    farmwares = Farmbot.BotState.force_state_push.process_info.farmwares
    for {name, _farmware} <- farmwares do
      {:ok, fw} = Farmbot.Farmware.lookup(name)
      Farmbot.BotState.unregister_farmware(fw)
      Farmbot.Farmware.Installer.uninstall(fw)
    end
  end

  defp test_credentials(_email, secret, server) do
    Logger.debug 3, "Testing credentials."
    user = %{credentials: secret |> :base64.encode_to_string |> to_string}
    payload = Poison.encode!(%{user: user})
    Farmbot.Bootstrap.Authorization.request_token(server, payload)
  end

end
