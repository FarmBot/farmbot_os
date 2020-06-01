defmodule FarmbotCore.FirmwareTTYDetector do
  use GenServer
  require Logger

  @doc "Gets the detected TTY"
  def tty(_server \\ __MODULE__) do
    "ttyAMA0"
  end

  def tty!(server \\ __MODULE__) do
    tty(server) || raise "No TTY detected"
  end

  @doc "Sets a TTY as detected by some other means"
  def set_tty(server \\ __MODULE__, tty) when is_binary(tty) do
    :ok
  end

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init([]) do
    {:ok, nil, 0}
  end
end
