defmodule Farmbot.Firmware.Transport do
  # @type args() :: Keyword.t()
  # @callback transport_init(args) :: {:ok, private} | {:error, reason}
end
