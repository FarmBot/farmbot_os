defmodule Farmbot.CeleryScript.AST.Node.ConfigUpdate do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  allow_args [:package]

  def execute(%{package: :farmbot_os}, _body, env) do
    msg = "`config_update` for FBOS is depricated."
    env = mutate_env(env)
    {:error, msg, env}
  end

  def execute(%{package: :arduino_firmware}, body, env) do
    msg = "`config_update` for Arduino Firmware is depricated."
    env = mutate_env(env)
    {:error, msg, env}
  end
end
