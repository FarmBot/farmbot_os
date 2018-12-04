defmodule Farmbot.OS.IOLayer.MoveRelative do
  @moduledoc false

  alias Farmbot.Firmware
  require Farmbot.Logger

  def execute(%{x: x, y: y, z: z, speed: s}, _body) do
    Farmbot.Logger.info(1, "starting relative movement: #{x}, #{y}, #{z}")

    with {:ok, {_, {:report_paramater_value, [movement_max_spd_x: max_spd_x]}}} <-
           Firmware.request({:paramater_read, [:movement_max_spd_x]}),
         {:ok, {_, {:report_paramater_value, [movement_max_spd_y: max_spd_y]}}} <-
           Firmware.request({:paramater_read, [:movement_max_spd_y]}),
         {:ok, {_, {:report_paramater_value, [movement_max_spd_z: max_spd_z]}}} <-
           Firmware.request({:paramater_read, [:movement_max_spd_z]}),
         {:ok, {_, {:report_position, [x: cur_x, y: cur_y, z: cur_z]}}} <-
           Firmware.request({:position_read, []}) do
      x_pos = x / 1.0 + cur_x
      x_spd = s / 100 * max_spd_x

      y_pos = y / 1.0 + cur_y
      y_spd = s / 100 * max_spd_y

      z_pos = z / 1.0 + cur_z
      z_spd = s / 100 * max_spd_z
      do_move(x_pos, x_spd, y_pos, y_spd, z_pos, z_spd)
    else
      error ->
        Farmbot.Logger.error(1, "Relative movement failed: #{inspect(error)}")
        {:error, "Firmware Error"}
    end
  end

  def do_move(x_pos, x_spd, y_pos, y_spd, z_pos, z_spd) do
    command_args = [x: x_pos, y: y_pos, z: z_pos, a: x_spd, b: y_spd, c: z_spd]

    case Firmware.command({:command_movement, command_args}) do
      :ok ->
        Farmbot.Logger.success(1, "Relative movement complete")
        :ok

      error ->
        Farmbot.Logger.error(1, "Relative movement failed: #{inspect(error)}")
        {:error, "Firmware Error"}
    end
  end
end
