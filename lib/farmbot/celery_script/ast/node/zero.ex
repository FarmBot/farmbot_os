defmodule Farmbot.CeleryScript.AST.Node.Zero do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:axis]

  def execute(%{axis: :all}, _, env) do
    env = mutate_env(env)
    do_reduce([:z, :y, :x], env)
  end

  def execute(%{axis: axis}, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.zero(axis) do
      :ok -> {:ok, env}
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
end
