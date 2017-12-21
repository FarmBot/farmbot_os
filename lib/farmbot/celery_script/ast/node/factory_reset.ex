defmodule Farmbot.CeleryScript.AST.Node.FactoryReset do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]
  use Farmbot.Logger

  def execute(%{package: :farmbot_os}, _, env) do
    env = mutate_env(env)
    Farmbot.BotState.set_sync_status(:maintenance)
    Farmbot.BotState.force_state_push()
    Farmbot.System.ConfigStorage.update_config_value(:bool, "settings", "disable_factory_reset", false)
    Logger.warn 1, "Farmbot OS going down for factory reset!"
    Farmbot.System.factory_reset "CeleryScript request."
    {:ok, env}
  end

  def execute(%{package: :arduino_firmware}, _, env) do
    env = mutate_env(env)
    Farmbot.BotState.set_sync_status(:maintenance)
    Logger.warn 1, "Arduino Firmware going down for factory reset!"
    params = Farmbot.System.ConfigStorage.get_config_as_map["hardware_params"]
    for {param, _val} <- params do
      Farmbot.Firmware.update_param(:"#{param}", -1)
    end

    Farmbot.BotState.force_state_push()
    Farmbot.Firmware.read_all_params()
    Farmbot.System.reboot("Arduino factory reset.")
    {:ok, env}
  end
end
