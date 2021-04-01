defmodule FarmbotCore.Firmware.Param do
  @type t() :: atom()
  def to_human(calib_param, value) do
    str = "to_human(#{inspect(calib_param)}, #{inspect(value)})"
    FarmbotCore.Firmware.wip(str)
  end
end
