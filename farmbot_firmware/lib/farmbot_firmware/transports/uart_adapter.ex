defmodule FarmbotFirmware.UartAdapter do
  @type gcode :: String.t()
  @type device_path :: String.t()
  @type uart_pid :: pid()
  @type not_known :: any()
  @type uart_opts :: any()

  @callback start_link() :: not_known
  @callback open(uart_pid, device_path, uart_opts) :: not_known
  @callback stop(uart_pid) :: not_known
  @callback write(uart_pid, gcode) :: not_known
  @callback generate_opts() :: not_known

  def adapter do
    raise("FIX THIS")
    # Application.get_env(:farmbot, :muon_trap_adapter, Avrdude.MuonTrapDefaultAdapter)
  end

  def cmd(exe, args, options) do
    adapter().cmd(exe, args, options)
  end
end
