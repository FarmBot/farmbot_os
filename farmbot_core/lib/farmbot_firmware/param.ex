defmodule FarmbotFirmware.Param do
  @type t() :: atom()
  def to_human(calib_param, value) do
    str = "to_human(#{inspect(calib_param)}, #{inspect(value)})"
    FarmbotFirmware.wip(str)
  end
end
