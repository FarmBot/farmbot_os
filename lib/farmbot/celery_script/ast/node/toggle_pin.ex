defmodule Farmbot.CeleryScript.AST.Node.TogglePin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number]
  use Farmbot.Logger

  def execute(%{pin_number: num}, _, env) do
    env = mutate_env(env)
    case Farmbot.BotState.get_pin_value(num) do
      {:ok, 0}  ->
        args = %{pin_mode: :digital, pin_number: num, pin_value: 1}
        Node.WritePin.execute(args, [], env)
      {:ok, 1}  ->
        args = %{pin_mode: :digital, pin_number: num, pin_value: 0}
        Node.WritePin.execute(args, [], env)
      res when res == {:ok, -1} or res == {:error, :unknown_pin} ->
        Logger.warn 2, "Unknown pin value. Setting to zero."
        args = %{pin_mode: :digital, pin_number: num, pin_value: 0}
        Node.WritePin.execute(args, [], env)
      {:error, reason} -> {:error, reason, env}
    end
  end
end
