defmodule Farmbot.CeleryScript.AST.Node.CheckUpdates do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]

  def execute(%{package: :farmbot_os}, _, env) do
    env = mutate_env(env)
    spawn __MODULE__, :nerves_hub_updater, []
    {:ok, env}
  end

  def execute(%{package: :arduino_firmware}, _, env) do
    env = mutate_env(env)
    {:error, "Arduino firmware can not be updated manually.", env}
  end

  def execute(%{package: {:farmware, _fw}} = args, _, env) do
    env = mutate_env(env)
    Farmbot.CeleryScript.AST.Node.UpdateFarmware.execute(args, [], env)
  end

  def nerves_hub_updater() do
    Farmbot.System.NervesHub.check_update()
  end
end
