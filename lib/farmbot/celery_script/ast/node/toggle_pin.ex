defmodule Farmbot.CeleryScript.AST.Node.TogglePin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number]

  def execute(%{pin_number: num}, _, env) do
    case Farmbot.Firmware.read_pin(num, :digital) do
      {:ok, 0} -> Node.WritePin.execute(%{pin_mode: :digital, pin_number: num, pin_value: 1}, [], env)
      {:ok, 1} -> Node.WritePin.execute(%{pin_mode: :digital, pin_number: num, pin_value: 0}, [], env)
      {:error, reason} -> {:error, reason, env}
    end
  end
end
