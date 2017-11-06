defmodule Farmbot.CeleryScript.AST.Node.ReadPin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number, :label, :pin_mode]

  def execute(%{pin_number: pin_num, pin_mode: mode}, _, env) do
    case Farmbot.Firmware.read_pin(pin_num, mode) do
      {:ok, _} -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
