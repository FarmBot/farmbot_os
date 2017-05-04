defmodule Farmbot.Serial.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger
  alias Nerves.UART
  alias Farmbot.Serial.Handler

  @baud 115_200

  @doc """
    Start the serial supervisor
  """
  def start_link do
    Logger.info ">> is starting serial services"
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      # Here we start a task for opening ttys. Since they can change depending
      # on who made the arduino, what drivers are running etc, we cant hard
      # code it.
      worker(Task, [__MODULE__, :open_ttys, [__MODULE__]], restart: :transient)
    ]
    supervise(children, strategy: :one_for_all)
  end

  if Mix.Project.config[:target] != "host" do

    # if runnin on the device, enumerate any uart devices and open them
    # individually.
    @spec open_ttys(atom | pid, [binary]) :: :ok | no_return
    def open_ttys(supervisor, ttys \\ nil) do
      blah = ttys || UART.enumerate() |> Map.drop(["ttyS0","ttyAMA0"]) |> Map.keys
      case blah do
        [one_tty] ->
          thing = {one_tty, [name: Farmbot.Serial.Handler]}
          try_open([thing], supervisor)
        ttys when is_list(ttys) ->
          ttys
          |> Enum.map(fn(device) -> {device, []} end)
          |> try_open(supervisor)
      end
    end
  else

    # If running in the host environment the proper tty is expected to be in
    # the environment
    defp get_tty do
      System.get_env("ARDUINO_TTY") || Application.get_env(:farmbot, :tty)
    end

    @spec open_ttys(atom | pid, [binary]) :: :ok | no_return
    def open_ttys(supervisor, list \\ nil)
    def open_ttys(supervisor, _) do
      if get_tty() do
        thing = {get_tty(), [name: Farmbot.Serial.Handler]}
        try_open([thing], supervisor)
      else
        Logger.warn ">> EXPORT ARDUINO_TTY to initialize arduino in Host mode"
        :ok
      end
    end

  end

  @spec try_open([{binary, [any]}], atom | pid) :: :ok | no_return
  defp try_open([], _), do: :ok
  defp try_open([{tty, opts} | rest], sup) do
    {:ok, nerves} = UART.start_link()
    nerves
    |> UART.open(tty, speed: @baud, active: false)
    |> bleep({tty, opts}, sup, nerves)

    try_open(rest, sup)
  end

  @spec bleep(any, binary, atom | pid, atom | pid)
    :: {:ok, pid} | false | no_return
  defp bleep(:ok, {tty, opts}, sup, nerves) do
    worker_spec = worker(Handler, [nerves, tty, opts], [restart: :permanent])
    UART.close(nerves)
    Process.sleep(1500)
    {:ok, _pid} = Supervisor.start_child(sup, worker_spec)
  end

  defp bleep(resp, {tty, _opts}, _, nerves) do
    Logger.error "Could not open #{tty}: #{inspect resp}"
    GenServer.stop(nerves, :normal)
    false
  end
end
