defmodule Farmbot.CeleryScript.AST.Node.SetPinIoMode do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:pin_io_mode, :pin_number]

  def execute(%{pin_number: number, pin_io_mode: mode}, _, env) do
    case Farmbot.Firmware.set_pin_mode(number, mode) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
