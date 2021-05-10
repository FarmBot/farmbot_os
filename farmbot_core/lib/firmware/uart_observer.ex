defmodule FarmbotCore.Firmware.UARTObserver do
  require Logger
  require FarmbotCore.Logger

  alias __MODULE__, as: State
  alias FarmbotCore.AssetWorker.FarmbotCore.Asset.FirmwareConfig
  alias FarmbotCore.Firmware.UARTCore
  alias FarmbotCore.Firmware.UARTCoreSupport, as: Support
  alias FarmbotCore.Firmware.ConfigUploader

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
    uart_pid = maybe_start_uart()

    unless uart_pid do
      Logger.info("No suitable UART devices found. Retrying.")
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

    refresh_config(state.uart_pid, diff)

    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.debug("##### UNKNOWN ##### " <> inspect(message))
    {:noreply, state}
  end

  defp try_to_attach_uart() do
    Process.send_after(self(), :connect_uart, 5_000)
  end

  defp maybe_start_uart do
    config = ConfigUploader.maybe_get_config()
    path = guess_uart(config)

    if path do
      if config && Support.needs_flash?() do
        FarmbotCore.Firmware.Flash.raw_flash(config.firmware_hardware, path)
      end

      {:ok, uart_pid} = UARTCore.start_link(path: path)
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

  defp guess_uart(%{firmware_path: path}) do
    # Just because the user has a `firmware_path` doesn't
    # mean the device is plugged in- verify before
    # proceeding. Otherwise, try to guess.
    if Support.device_available?(path) do
      path
    else
      guess_uart(nil)
    end
  end

  defp uart_list() do
    Support.enumerate()
    |> Map.keys()
    |> Enum.filter(&filter_uart/1)
  end

  defp filter_uart("ttyACM" <> _), do: true
  defp filter_uart("ttyAMA" <> _), do: true
  defp filter_uart("ttyUSB" <> _), do: true
  defp filter_uart(_), do: false

  defp refresh_config(nil, _), do: :noop
  defp refresh_config(_, []), do: :noop
  defp refresh_config(pid, keys), do: UARTCore.refresh_config(pid, keys)
end
