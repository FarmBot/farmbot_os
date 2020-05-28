defmodule FarmbotCore.FirmwareTTYDetector do
  use GenServer
  require Logger
  alias Circuits.UART

  @error_retry_ms 5_000

  if System.get_env("FARMBOT_TTY") do
    @expected_names ["ttyUSB0", "ttyAMA0", "ttyACM0", System.get_env("FARMBOT_TTY")]
  else
    @expected_names ["ttyUSB0", "ttyAMA0", "ttyACM0"]
  end

  @doc "Gets the detected TTY"
  def tty(server \\ __MODULE__) do
    GenServer.call(server, :tty)
  end

  def tty!(server \\ __MODULE__) do
    tty(server) || raise "No TTY detected"
  end

  @doc "Sets a TTY as detected by some other means"
  def set_tty(server \\ __MODULE__, tty) when is_binary(tty) do
    GenServer.call(server, {:tty, tty})
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

  def handle_call({:tty, detected_tty}, _from, _old_value) do
    {:reply, :ok, detected_tty}
  end

  def handle_info(:timeout, state) do
    # This was a feature request by a DIY user that experienced
    # problems while using third party boards.
    # The comparator function below always puts ttyAMA0 at the
    # end of the list to prevent problems with these baords.
    # ama0_always_last = fn
    #   {"ttyAMA0", _} -> "z"
    #   _ -> "a"
    # end

    enumerated = UART.enumerate()
    |> Map.to_list()
    # |> Enum.sort_by(ama0_always_last)

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
    Process.send_after(self(), :timeout, @error_retry_ms)
    {:noreply, state}
  end

  defp farmbot_tty?(file_path) do
    file_path in @expected_names
  end
end
