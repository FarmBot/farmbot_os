defmodule FarmbotOS.FirmwareTTYDetector do
  use GenServer
  require Logger
  require FarmbotCore.Logger
  alias Circuits.UART

  alias FarmbotFirmware.UARTTransport
  alias FarmbotCore.FirmwareSupervisor
  alias FarmbotCore.FirmwareSideEffects
  alias FarmbotCore.{Asset, BotState}

  @expected_names Application.get_env(:farmbot, __MODULE__)[:expected_names]
  @expected_names ||
    Mix.raise("""
    Please configure `expected_names` for TTYDetector.

        config :farmbot, Farmbot.TTYDetector,
          expected_names: ["ttyS0", "ttyNotReal"]
    """)

  def tty(server \\ __MODULE__) do
    GenServer.call(server, :tty)
  end

  def tty!(server \\ __MODULE__) do
    tty(server) || raise "No TTY detected"
  end

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init([]) do
    {:ok, nil, 0}
  end

  def handle_call(:tty, _, detected_tty) do
    {:reply, detected_tty, detected_tty}
  end

  def handle_info(:timeout, state) do
    enumerated = UART.enumerate() |> Map.to_list()
    {:noreply, state, {:continue, enumerated}}
  end

  def handle_continue([{name, _} | rest], state) do
    if farmbot_tty?(name) do
      {:noreply, name}
    else
      {:noreply, state, {:continue, rest}}
    end
  end

  def handle_continue([], state) do
    {:noreply, state}
  end

  defp farmbot_tty?(file_path) do
    file_path in @expected_names
  end
end
