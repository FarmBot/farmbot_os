defmodule Farmbot.CeleryScript.AST.Node.Home do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:speed, :axis]

  def execute(%{axis: :all}, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.home_all() do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

  def execute(%{axis: axis}, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.home(axis) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
