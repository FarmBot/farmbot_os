defmodule FarmbotCore.FirmwareOpenTask do
  @moduledoc """
  Will open the UART interface after it's been successfully flashed .
  Must configure in application env: `attempt_threshold`. It can be an integer
  or `:infinity` in which case it will try opening it indefinately. 
  """
  
  use GenServer
  require FarmbotCore.Logger
  alias FarmbotFirmware.UARTTransport
  alias FarmbotCore.{Asset, Config}
  @attempt_threshold Application.get_env(:farmbot_core, __MODULE__)[:attempt_threshold]
  @attempt_threshold || Mix.raise """
  Firmware open attempt threshold not configured:

  config :farmbot_core, FarmbotCore.FirmwareOpenTask, [
    attempt_threshold: 10
  ]
  """

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @doc false
  def swap_transport(tty) do
    Application.put_env(:farmbot_firmware, FarmbotFirmware, transport: UARTTransport, device: tty)
    # Swap transport on FW module.
    # Close tranpsort if it is open currently.
    _ = FarmbotFirmware.close_transport()
    FarmbotFirmware.open_transport(UARTTransport, device: tty)
  end

  @impl GenServer
  def init(_args) do
    send(self(), :open)
    {:ok, %{timer: nil, attempts: 0, threshold: @attempt_threshold}}
  end

  @impl GenServer
  def handle_info(:open, %{attempts: at, threshold: attempt_threshold} = state) when at >= attempt_threshold do
    if state.timer, do: Process.cancel_timer(state.timer)
    FarmbotCore.Logger.debug 3, "Firmware didn't open after #{@attempt_threshold} tries. Not trying to open anymore"
    {:noreply, %{state | timer: nil}}
  end
  
  def handle_info(:open, state) do
    if state.timer, do: Process.cancel_timer(state.timer)

    needs_flash? = Config.get_config_value(:bool, "settings", "firmware_needs_flash")
    needs_open? = Config.get_config_value(:bool, "settings", "firmware_needs_open")
    firmware_path = Asset.fbos_config(:firmware_path)
    cond do
      needs_flash? ->
        FarmbotCore.Logger.debug 3, "Firmware needs flash still. Not opening"
        timer = Process.send_after(self(), :open, 5000)
        {:noreply, increment_attempts(%{state | timer: timer})}

      is_nil(firmware_path) ->
        FarmbotCore.Logger.debug 3, "Firmware path not detected. Not opening"
        timer = Process.send_after(self(), :open, 5000)
        {:noreply, increment_attempts(%{state | timer: timer})}

      needs_open? ->
        FarmbotCore.Logger.debug 3, "Firmware needs to be opened"
        case swap_transport(firmware_path) do
          :ok -> 
            {:noreply, %{state | timer: nil, attempts: 0}, :hibernate}
          _ ->
            FarmbotCore.Logger.debug 3, "Firmware failed to open"
            timer = Process.send_after(self(), :open, 5000)
            {:noreply, %{state | timer: timer, attempts: 0}}
        end
      true ->
        FarmbotCore.Logger.debug 3, """
        Unknown firmware open state:
        firmware needs flash?: #{needs_flash?}
        firwmare needs open?: #{needs_open?}
        firmware path: #{firmware_path}
        """
        timer = Process.send_after(self(), :open, 5000)
        {:noreply, %{state | timer: timer, attempts: 0}}
    end
  end

  defp increment_attempts(%{attempts: at, attempt_threshold: :infinity} = state) do
    %{state | attempts: at + 1}
  end

  defp increment_attempts(%{attempts: at} = state) do
    %{state | attempts: at + 1}
  end
end
