defmodule Farmbot.CeleryScript.AST.Node.ChangeOwnership do
  @moduledoc false

  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.System.ConfigStorage
  allow_args []

  def execute(_, pairs, env) do
    env = mutate_env(env)
    pair_map = Map.new(pairs,
      fn(%{args: %{label: label, value: value}}) -> {label, value} end)
    email = pair_map["email"]
    secret = pair_map["secret"]
    server = pair_map["server"]
    Farmbot.BotState.set_sync_status(:maintenance)
    ConfigStorage.update_config_value(:string, "authorization", "email", email)
    ConfigStorage.update_config_value(:string, "authorization", "server", server)
    ConfigStorage.update_config_value(:string, "authorization", "password", secret)
    ConfigStorage.update_config_value(:string, "authorization", "token", nil)
    repos = [Farmbot.Repo.A, Farmbot.Repo.B]
    resources = [
      Farmbot.Repo.Device,
      Farmbot.Repo.FarmEvent,
      Farmbot.Repo.Peripheral,
      Farmbot.Repo.Point,
      Farmbot.Repo.Regimen,
      Farmbot.Repo.Sequence,
      Farmbot.Repo.ToolSlot,
      Farmbot.Repo.Tool
    ]
    for repo <- repos do
      for resource <- resources do
        repo.delete_all(resource)
      end
    end

    farmwares = Farmbot.BotState.force_state_push.process_info.farmwares
    for {name, farmware} <- farmwares do
      {:ok, fw} = Farmbot.Farmware.lookup(name)
      Farmbot.BotState.unregister_farmware(fw)
      Farmbot.Farmware.Installer.uninstall(fw)
    end
    Farmbot.System.reboot("Change ownership")
    {:ok, env}
  end

end
