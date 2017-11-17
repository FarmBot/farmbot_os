defmodule Farmbot.CeleryScript.AST.Node.FindHome do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:speed, :axis]

  def execute(%{speed: speed, axis: :all}, _, env) do
    env = mutate_env(env)
    do_reduce([:y, :z, :x], speed, env)
  end

  def execute(%{speed: speed, axis: axis}, _, env) do
    env = mutate_env(env)
    ep = Farmbot.BotState.get_param(:"movement_enable_endpoints_#{axis}")
    ec = Farmbot.BotState.get_param(:"encoder_enabled_#{axis}")
    do_find_home(ep, ec, axis, speed, env)
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

  defp do_find_home(ep, ec, axis, speed, env)
  defp do_find_home(ep, ec, axis, _, env) when (ep == 0) or (ep == nil) or (ec == 0) or (ec == nil) do
    {:error, "Could not find home on #{axis} axis because endpoints and encoders are disabled.", env}
  end
  defp do_find_home(ep, ec, axis, speed, env) when ep == 1 or ec == 1 do
    case Farmbot.Firmware.find_home(axis, speed) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
