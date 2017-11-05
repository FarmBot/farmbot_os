defmodule Farmbot.CeleryScript.AST.Node.FindHome do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:speed, :axis]

  def execute(%{speed: speed, axis: :all}, _, env) do
    do_reduce([:y, :z, :x], speed, env)
  end

  def execute(%{speed: speed, axis: axis}, _, env) do
    case Farmbot.Firmware.find_home(axis, speed) do
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
