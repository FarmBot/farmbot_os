defmodule FarmbotCore.Firmware.UARTObserver do
  require Logger

  alias __MODULE__, as: State
  alias FarmbotCore.AssetWorker.FarmbotCore.Asset.FirmwareConfig
  alias FarmbotCore.Firmware.UARTCore

  defstruct uart_pid: nil

  def data_available(pid \\ __MODULE__, from) do
    send(pid, {:data_available, from})
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_) do
    try_to_attach_uart()
    {:ok, %State{}}
  end

  def handle_info(:connect_uart, %{uart_pid: nil}) do
    uart_pid = maybe_get_uart_pid()

    unless uart_pid do
      Logger.info("==== Retrying UART connection...")
      try_to_attach_uart()
    end

    {:noreply, %State{uart_pid: uart_pid}}
  end

  def handle_info({:data_available, FirmwareConfig}, state) do
    old_config = FarmbotCore.BotState.fetch().mcu_params
    new_config = FarmbotCore.Asset.firmware_config()

    diff =
      old_config
      |> Map.to_list()
      |> Enum.map(fn {key, old_value} ->
        new_value = Map.get(new_config, key)

        if new_value do
          if FarmbotFirmware.Parameter.is_param?(key) do
            if new_value != old_value do
              key
            end
          end
        end
      end)
      |> Enum.reject(&is_nil/1)

    if is_pid(state.uart_pid) do
      UARTCore.refresh_config(state.uart_pid, diff)
    end

    {:noreply, state}
  end

  def handle_info({:data_available, from}, state) do
    IO.inspect(from, label: "##### DATA AVAILABLE #####")
    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.inspect(message, label: "##### UNKNOWN #####")
    {:noreply, state}
  end

  defp try_to_attach_uart() do
    Process.send_after(self(), :connect_uart, 3_000)
  end

  defp maybe_get_uart_pid do
    path = guess_uart(FarmbotCore.Firmware.ConfigUploader.maybe_get_config())

    if path do
      {:ok, uart_pid} = FarmbotCore.Firmware.UARTCore.start_link(path: path)
      uart_pid
    end
  end

  # If the `firmware_path` is not set, we can still try to
  # guess. We only guess if there is _EXACTLY_ one serial
  # device. This is to prevent interference with DIY setups.
  defp guess_uart(nil) do
    case uart_list() do
      [default_uart] -> default_uart
      _ -> nil
    end
  end

  defp guess_uart(config) do
    config.firmware_path || guess_uart(nil)
  end

  defp uart_list() do
    Circuits.UART.enumerate()
    |> Map.keys()
    |> Enum.filter(&filter_uart/1)
  end

  defp filter_uart("ttyACM" <> _), do: true
  defp filter_uart("ttyAMA" <> _), do: true
  defp filter_uart("ttyUSB" <> _), do: true
  defp filter_uart(_), do: false
end
