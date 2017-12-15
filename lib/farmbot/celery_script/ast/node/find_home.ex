defmodule Farmbot.CeleryScript.AST.Node.FindHome do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:speed, :axis]
  use Farmbot.Logger

  def execute(%{axis: :all}, _, env) do
    env = mutate_env(env)
    do_reduce([:z, :y, :x], env)
  end

  def execute(%{axis: axis}, _, env) do
    env = mutate_env(env)
    ep = Farmbot.BotState.get_param(:"movement_enable_endpoints_#{axis}")
    ec = Farmbot.BotState.get_param(:"encoder_enabled_#{axis}")
    do_find_home(ep, ec, axis, env)
  end

  defp do_reduce([axis | rest], env) do
    case execute(%{axis: axis}, [], env) do
      {:ok, new_env} -> do_reduce(rest, new_env)
      {:error, reason, env} -> {:error, reason, env}
    end
  end

  defp do_reduce([], env) do
    {:ok, env}
  end

  defp do_find_home(ep, ec, axis, env)

  defp do_find_home(ep, ec, axis, env) when ((ep == 0) or (ep == nil)) and ((ec == 0) or (ec == nil)) do
    {:error, "Could not find home on #{axis} axis because endpoints and encoders are disabled.", env}
  end

  defp do_find_home(ep, ec, axis, env) when ep == 1 or ec == 1 do
    Logger.busy 2, "Finding home on #{axis} axis."
    case Farmbot.Firmware.find_home(axis) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_find_home(ep, ec, _axis, env) do
    {:error, "Unknown  state of endpoints: #{ep} or encoders: #{ec}", env}
  end

end
