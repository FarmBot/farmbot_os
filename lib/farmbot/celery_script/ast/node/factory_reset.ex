defmodule Farmbot.CeleryScript.AST.Node.FactoryReset do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]
  use Farmbot.Logger

  def execute(%{package: :farmbot_os}, _, env) do
    env = mutate_env(env)
    Logger.warn 1, "Going down for factory reset!"
    Farmbot.System.factory_reset "CeleryScript request."
    {:ok, env}
  end

  def execute(%{package: :arduino_firmware}, _, env) do
    env = mutate_env(env)
    params = Farmbot.System.ConfigStorage.get_config_as_map["hardware_params"]
    for {param, _val} <- params do
      Farmbot.Firmware.update_param(:"#{param}", -1)
    end

    Farmbot.Firmware.read_all_params()
    Farmbot.System.reboot("Arduino factory reset.")
    {:ok, env}
  end
end
