defmodule Farmbot.CeleryScript.AST.Node.Zero do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  allow_args [:axis]

  def execute(%{axis: :all}, _, env) do
    env = mutate_env(env)
    do_reduce([:z, :y, :x], env)
  end

  def execute(%{axis: axis}, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.zero(axis) do
      :ok -> do_wait_for_pos(axis, env)
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_reduce([axis | rest], env) do
    case execute(%{axis: axis}, [], env) do
      {:ok, new_env} -> do_reduce(rest, new_env)
      {:error, _, _} = err -> err
    end
  end

  defp do_reduce([], env) do
    {:ok, env}
  end

  @default_num_tries 20
  defp do_wait_for_pos(axis, env, tries \\ @default_num_tries)

  defp do_wait_for_pos(axis, env, 0) do
    {:error, "Failed to set #{axis} location to 0", env}
  end

  defp do_wait_for_pos(axis, env, tries) do
    current_pos = Farmbot.BotState.get_current_pos()
    if current_pos[axis] == 0 do
      Logger.success 1, "Current #{axis} location set to 0"
      {:ok, env}
    else
      Process.sleep(500)
      do_wait_for_pos(axis, env, tries - 1)
    end
  end
end
