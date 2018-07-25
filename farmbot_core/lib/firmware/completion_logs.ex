defmodule Farmbot.Firmware.CompletionLogs do
  @moduledoc false
  require Farmbot.Logger
  import Farmbot.Config, only: [get_config_value: 3]
  alias Farmbot.Firmware.Command

  def maybe_log_complete(%Command{fun: :move_absolute, args: [pos | _]}, {:error, _reason}) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.error 1, "Movement to #{inspect pos} failed."
    end
  end

  def maybe_log_complete(%Command{fun: :move_absolute, args: [pos | _]} = current, _reply) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      if current.status do
        pos = Enum.reduce(current.status, pos, fn(status, pos) ->
          case status do
            {:report_axis_changed_x, new_pos} -> %{pos | x: new_pos}
            {:report_axis_changed_y, new_pos} -> %{pos | y: new_pos}
            {:report_axis_changed_z, new_pos} -> %{pos | z: new_pos}
            _ -> pos
          end
        end)
        Farmbot.Logger.success 1, "Movement to #{inspect pos} complete. (Stopped at end)"
      else
        Farmbot.Logger.success 1, "Movement to #{inspect pos} complete."
      end
    end
  end

  def maybe_log_complete(%Command{fun: :home}, {:error, _reason}) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.error 1, "Movement to (0, 0, 0) failed."
    end
  end

  def maybe_log_complete(%Command{fun: :home_all}, _reply) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.success 1, "Movement to (0, 0, 0) complete."
    end
  end

  def maybe_log_complete(_command, {:error, :report_axis_home_complete_x}) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.success 2, "X Axis homing complete."
    end
  end

  def maybe_log_complete(_command, {:error, :report_axis_home_complete_y}) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.success 2, "Y Axis homing complete."
    end
  end

  def maybe_log_complete(_command, {:error, :report_axis_home_complete_z}) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.success 2, "Z Axis homing complete."
    end
  end

  def maybe_log_complete(_command, {:error, :report_axis_timeout_x}) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.error 2, "X Axis timeout."
    end
  end

  def maybe_log_complete(_command, {:error, :report_axis_timeout_y}) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.error 2, "Y Axis timeout."
    end
  end

  def maybe_log_complete(_command, {:error, :report_axis_timeout_z}) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.error 2, "Z Axis timeout."
    end
  end

  def maybe_log_complete(_command, _result) do
    # IO.puts "#{command} => #{inspect result}"
    :ok
  end
end
