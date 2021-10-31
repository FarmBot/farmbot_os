defmodule FarmbotOS.Firmware.UARTObserver do
  require Logger
  require FarmbotOS.Logger

  alias __MODULE__, as: State
  alias FarmbotOS.AssetWorker.FarmbotOS.Asset.FirmwareConfig
  alias FarmbotOS.Firmware.UARTCore
  alias FarmbotOS.Firmware.UARTCoreSupport, as: Support

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
    Process.send_after(self(), :connect_uart, 5_000)
    FarmbotOS.Leds.red(:slow_blink)
    {:ok, %State{}}
  end

  def handle_info(:connect_uart, %{uart_pid: nil}) do
    uart_pid = maybe_start_uart()

    unless uart_pid do
      Process.send_after(self(), :connect_uart, 5_000)
    end

    {:noreply, %State{uart_pid: uart_pid}}
  end

  def handle_info({:data_available, FirmwareConfig}, state) do
    old_config = FarmbotOS.BotState.fetch().mcu_params
    new_config = FarmbotOS.Asset.firmware_config()

    diff =
      old_config
      |> Map.to_list()
      |> Enum.map(fn {key, old_value} ->
        new_value = Map.get(new_config, key)

        if new_value do
          if FarmbotOS.Firmware.Parameter.is_param?(key) do
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

  defp maybe_start_uart do
    {package, path} = FarmbotOS.Firmware.UARTDetector.run()

    if path && package do
      if Support.recent_boot?() do
        FarmbotOS.Firmware.Flash.raw_flash(package, path)
      end

      {:ok, uart_pid} = UARTCore.start_link(path: path, fw_type: package)
      uart_pid
    end
  end

  defp refresh_config(nil, _), do: :noop
  defp refresh_config(_, []), do: :noop
  defp refresh_config(pid, keys), do: UARTCore.refresh_config(pid, keys)
end
