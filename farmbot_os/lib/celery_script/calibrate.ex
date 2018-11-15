defmodule Farmbot.OS.IOLayer.Calibrate do
  @moduledoc false

  alias Farmbot.Firmware

  def execute(%{axis: "all"} = args, body) do
    with :ok <- execute(%{args | axis: "z"}, body),
         :ok <- execute(%{args | axis: "y"}, body),
         :ok <- execute(%{args | axis: "x"}, body) do
      :ok
    end
  end

  def execute(%{axis: axis}, _body) do
    command = {:command_movement_calibrate, [String.to_existing_atom(axis)]}

    case Firmware.command(command) do
      :ok -> :ok
      _ -> {:error, "Firmware Error"}
    end
  end
end
