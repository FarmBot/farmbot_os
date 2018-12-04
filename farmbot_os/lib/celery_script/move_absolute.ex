defmodule Farmbot.OS.IOLayer.MoveAbsolute do
  @moduledoc false

  alias Farmbot.Firmware
  require Farmbot.Logger

  def execute(%{location: %{args: %{pointer_type: "Plant", pointer_id: id}}} = args, body) do
    Farmbot.Logger.debug(1, "Finding plant before movement")

    case Farmbot.Asset.get_point(id: id) do
      %{x: pos_x, y: pos_y, z: pos_z} ->
        new_args = %{
          location: %{args: %{x: pos_x, y: pos_y, z: pos_z}},
          offset: args[:offset] || %{args: %{x: 0.0, y: 0.0, z: 0.0}}
        }

        execute(new_args, body)

      nil ->
        {:error, "Could not find plant by id: #{id}"}
    end
  end

  def execute(%{location: %{args: %{tool_id: id}}} = args, body) do
    Farmbot.Logger.debug(1, "Finding Tool before movement")

    case Farmbot.Asset.get_point(tool_id: id) do
      %{x: pos_x, y: pos_y, z: pos_z} ->
        new_args = %{
          location: %{args: %{x: pos_x, y: pos_y, z: pos_z}},
          offset: args[:offset] || %{args: %{x: 0.0, y: 0.0, z: 0.0}}
        }

        execute(new_args, body)

      nil ->
        {:error, "Could not find Tool by id: #{id}"}
    end
  end

  def execute(args, _body) do
    with %{args: %{x: pos_x, y: pos_y, z: pos_z}} <- args[:location],
         %{args: %{x: offset_x, y: offset_y, z: offset_z}} <- args[:offset],
         x <- offset_x + pos_x / 1.0,
         y <- offset_y + pos_y / 1.0,
         z <- offset_z + pos_z / 1.0,
         :ok <- Firmware.command({:command_movement, [x: x, y: y, z: z]}) do
      Farmbot.Logger.success(1, "Movement complete.")
      :ok
    else
      reason ->
        Farmbot.Logger.error(1, "Movement failed: #{inspect(reason)}")
        {:error, "Firmware Error"}
    end
  end
end
