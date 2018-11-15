defmodule Farmbot.OS.IOLayer.MoveAbsolute do
  @moduledoc false

  alias Farmbot.Firmware

  def execute(args, _body) do
    with %{args: %{x: pos_x, y: pos_y, z: pos_z}} <- args[:location],
         %{args: %{x: offset_x, y: offset_y, z: offset_z}} <- args[:offset],
         x <- offset_x + pos_x / 1.0,
         y <- offset_y + pos_y / 1.0,
         z <- offset_z + pos_z / 1.0,
         :ok <- Firmware.command({:command_movement, [x: x, y: y, z: z]}) do
      :ok
    else
      _ -> {:error, "Firmware Error"}
    end
  end
end
