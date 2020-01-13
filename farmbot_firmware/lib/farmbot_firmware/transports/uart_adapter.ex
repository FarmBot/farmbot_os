defmodule FarmbotFirmware.UartAdapter do
  alias Circuits.UART

  @type uart_pid :: GenServer.server()
  @type device_path :: binary()
  @type gcode :: iodata()
  @type not_known :: any()
  @type uart_opts :: [UART.uart_option()]
  @type uart_op_result :: :ok | {:error, term()}
  @type uart_start_link_result :: {:ok, pid()} | {:error, term()}

  @callback generate_opts() :: not_known
  @callback open(uart_pid, device_path, uart_opts) :: uart_op_result
  @callback start_link() :: uart_start_link_result
  @callback stop(uart_pid) :: :ok
  @callback write(uart_pid, gcode) :: uart_op_result
end
