defmodule Farmbot.CeleryScript.AST.Node.TogglePin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number]
  use Farmbot.Logger

  def execute(%{pin_number: num}, _, env) do
    env = mutate_env(env)
    case Farmbot.BotState.get_pin_value(num) do
      {:ok, 0}  -> high(env, num)
      {:ok, 1}  -> low(env, num)
      {:ok, _} -> unknown(env, num)
      {:error, :unknown_pin} -> unknown(env, num)
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp unknown(env, num) do
    Logger.warn 2, "Unknown pin value. Setting to zero."
    low(mutate_env(env), num)
  end

  defp high(env, num) do
    args = %{pin_mode: :digital, pin_number: num, pin_value: 1}
    jump(mutate_env(env), args)
  end

  defp low(env, num) do
    args = %{pin_mode: :digital, pin_number: num, pin_value: 0}
    jump(mutate_env(env), args)
  end

  defp jump(env, args), do: Node.WritePin.execute(args, [], mutate_env(env))
end
