defmodule FarmbotOS.Firmware.LuaUART do
  # uart = uart.open("ttyACM1", 115200)
  # data, error = uart.read(30000)
  # print(data)
  # error = uart.write("Hello, world!")
  def open([device, speed], lua) do
    {:ok, pid} = Circuits.UART.start_link()
    result = Circuits.UART.open(pid, device, speed: trunc(speed), active: false)
    do_open(result, pid, lua)
  end

  def list([], lua) do
    {[Map.keys(Circuits.UART.enumerate())], lua}
  end

  def new_uart(pid) do
    [
      {:read,
       fn [timeout], lua ->
         case Circuits.UART.read(pid, trunc(timeout)) do
           {:ok, data} -> {[data], lua}
           other -> {[nil, inspect(other)], lua}
         end
       end},
      {:close,
       fn [], lua ->
         close(pid)
         {[], lua}
       end},
      {:write,
       fn [data], lua ->
         case Circuits.UART.write(pid, data) do
           :ok -> {[nil], lua}
           other -> {[inspect(other)], lua}
         end

         {[], lua}
       end}
    ]
  end

  defp do_open(:ok, pid, lua), do: {[new_uart(pid), nil], lua}

  defp do_open({:error, :enoent}, pid, lua) do
    close(pid)
    {[nil, "UART device not found!"], lua}
  end

  defp do_open(error, pid, lua) do
    close(pid)
    {[nil, inspect(error)], lua}
  end

  defp close(pid) do
    Circuits.UART.close(pid)
    Circuits.UART.stop(pid)
  end
end
