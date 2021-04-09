defmodule FarmbotCore.Firmware.UARTObserver do
  alias __MODULE__, as: State
  alias FarmbotCore.Asset
  alias FarmbotFirmware.Parameter

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
    {:ok, refresh_data(%State{})}
  end

  def handle_info({:data_available, from}, state) do
    IO.inspect(from, label: "##### DATA AVAILABLE #####")
    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.inspect(message, label: "##### UNKNOWN #####")
    {:noreply, state}
  end

  defp refresh_data(state) do
    state |> Map.merge(fbos_config()) |> Map.merge(fw_config())
  end

  defp fbos_config do
    keys = [:firmware_hardware, :firmware_path]
    Map.take(Asset.fbos_config(), keys)
  end

  defp fw_config do
    Map.take(Asset.firmware_config(), Parameter.names())
  end
end
