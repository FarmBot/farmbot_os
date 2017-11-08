defmodule Farmbot.CeleryScript.AST.Node.TogglePin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number]
  use Farmbot.Logger

  def execute(%{pin_number: num}, _, env) do
    env = mutate_env(env)
    case Farmbot.BotState.get_pin_value(num) do
      {:ok, 0}  -> Node.WritePin.execute(%{pin_mode: :digital, pin_number: num, pin_value: 1}, [], env)
      {:ok, 1}  -> Node.WritePin.execute(%{pin_mode: :digital, pin_number: num, pin_value: 0}, [], env)
      res when res == {:ok, -1} or res == {:error, :unknown_pin} ->
        Logger.warn 2, "unknonw pin value. Setting to zero."
        Node.WritePin.execute(%{pin_mode: :digital, pin_number: num, pin_value: 0}, [], env)
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_get_pin_value(num, env) do
    case Farmbot.BotState.get_pin_value(num) do
      {:ok, 0}  -> Node.WritePin.execute(%{pin_mode: :digital, pin_number: num, pin_value: 1}, [], env)
      {:ok, 1}  -> Node.WritePin.execute(%{pin_mode: :digital, pin_number: num, pin_value: 0}, [], env)
      {:ok, -1} -> Node.WritePin.execute(%{pin_mode: :digital, pin_number: num, pin_value: 0}, [], env)
      {:error, reason} -> {:error, reason, env}
    end
  end
end
