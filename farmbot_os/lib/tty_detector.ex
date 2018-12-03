defmodule Farmbot.TTYDetector do
  use GenServer
  require Logger
  alias Circuits.UART

  import Farmbot.Config, only: [get_config_value: 3]

  @expected_names ["ttyACM0"]
  @error_ms 5000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:ok, %{device: nil, needs_flash: false, open: false}, 0}
  end

  def handle_info(:timeout, %{device: nil} = state) do
    case get_config_value(:string, "settings", "firmware_hardware") do
      nil -> {:noreply, state, @error_ms}
      _hw ->
        available = UART.enumerate() |> Map.to_list()
        {:noreply, state, {:continue, available}}
    end
  end

  def handle_info(:timeout, %{device: device, needs_flash: true} = state) do
    dir = Application.app_dir(:farmbot_core, ["priv"])
    case get_config_value(:string, "settings", "firmware_hardware") do
      "arduino" -> flash_fw(Path.join(dir, "arduino_firmware.hex"), state)
      "farmduino" -> flash_fw(Path.join(dir, "farmduino.hex"), state)
      "farmduino_k14" -> flash_fw(Path.join(dir, "farmduino_k14.hex"), state)
      nil -> {:noreply, state, @error_ms}
      other ->
        Logger.error "Unknown arduino firmware #{other}"
        {:stop, {:unknown_firmware, other}, state}
    end
  end

  def handle_info(:timeout, %{device: device, needs_flash: false, open: false} = state) do
    opts = [
      device: device,
      transport: Farmbot.Firmware.UARTTransport,
      side_effects: Farmbot.Core.FirmwareSideEffects
    ]
    case Farmbot.Firmware.start_link(opts) do
      {:ok, pid} -> 
        Process.monitor(pid)
        {:noreply, %{state | open: true}}
      error -> 
        {:stop, error, state}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    {:stop, reason, state}
  end

  def handle_continue([{name, _} | rest], %{device: nil} = state)
    when name in @expected_names do
    {:noreply, %{state | device: name}, 0}
  end

  def handle_continue([_ | rest], %{device: nil} = state) do
    {:noreply, state, {:continue, rest}}
  end

  def handle_continue([], %{device: nil} = state) do
    {:noreply, state, @error_ms}
  end

  defp flash_fw(fw_file, state) do
    args = ~w"-q -q -patmega2560 -cwiring -P#{dev(state.device)} -b115200 -D -V -Uflash:w:#{fw_file}:i"
    opts = [stderr_to_stdout: true, into: IO.stream(:stdio, :line)]
    res = System.cmd("avrdude", args, opts)
    case res do
      {_, 0} -> {:noreply, %{state | needs_flash: false}, 0}
      _ ->
        Logger.error("firmware flash failed")
        {:noreply, state, @error_ms}
    end
  end

  defp dev("/dev/" <> _ = device), do: IO.inspect(device, label: "DEVICE")
  defp dev("tty" <> _ = dev), do: IO.inspect(Path.join("/dev", dev), label: "DEVICE")
end
