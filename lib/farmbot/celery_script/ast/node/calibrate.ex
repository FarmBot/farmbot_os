defmodule Farmbot.CeleryScript.AST.Node.Calibrate do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:axis]

  @default_speed 100

  def execute(%{axis: :all}, _, env) do
    env = mutate_env(env)
    do_reduce([:y, :z, :x], @default_speed, env)
  end

  def execute(%{speed: speed, axis: axis}, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.calibrate(axis, speed) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_reduce([axis | rest], speed, env) do
    case execute(%{axis: axis, speed: speed}, [], env) do
      {:ok, new_env} -> do_reduce(rest, speed, new_env)
      {:error, reason, env} -> {:error, reason, env}
    end
  end

  defp do_reduce([], _, env) do
    {:ok, env}
  end
end
