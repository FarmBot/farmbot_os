defmodule FarmbotCore.Firmware.UARTObserver do
  alias __MODULE__, as: State

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
    config = FarmbotCore.Firmware.ConfigUploader.maybe_get_config()

    if config do
      IO.puts("FIX THIS- Handle `nil` cases.")
      path = config.firmware_path
      {:ok, uart_pid} = FarmbotCore.Firmware.UARTCore.start_link(path: path)
      {:ok, %State{uart_pid: uart_pid}}
    else
      {:ok, %State{}}
    end
  end

  def handle_info({:data_available, from}, state) do
    IO.inspect(from, label: "##### DATA AVAILABLE #####")
    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.inspect(message, label: "##### UNKNOWN #####")
    {:noreply, state}
  end
end
