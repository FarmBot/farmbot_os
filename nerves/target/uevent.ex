defmodule Farmbot.Target.Uevent.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(_,_) do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [worker(Farmbot.Target.Uevent, [])]
    supervise(children, [strategy: :one_for_one])
  end
end

defmodule Farmbot.Target.Uevent do
  @moduledoc false

  use GenServer
  use Farmbot.Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    executable = :code.priv_dir(:nerves_runtime) ++ '/uevent'
    port = Port.open({:spawn_executable, executable},
    [{:args, []},
      {:packet, 2},
      :use_stdio,
      :binary,
      :exit_status])

    {:ok, %{port: port}}
  end

  def handle_info({_, {:data, <<?n, message::binary>>}}, s) do
    msg = :erlang.binary_to_term(message)
    handle_port(msg, s)
  end

  defp handle_port({:uevent, _uevent, kv}, s) do
    event =
      Enum.reduce(kv, %{}, fn (str, acc) ->
        [k, v] = String.split(str, "=", parts: 2)
        k = String.downcase(k)
        Map.put(acc, k, v)
      end)
    case Map.get(event, "devpath", "") do
      "/devices" <> _path -> handle_uevent(event)
      _ -> :noop
    end
    {:noreply, s}
  end

  defp handle_uevent(%{"action" => "add", "subsystem" => "tty", "devname" => tty}) do
    Logger.busy 3, "Detected new UART Device: #{tty}"
    Application.put_env(:farmbot, :uart_handler, tty: "/dev/" <> tty)
    old_env = Application.get_env(:farmbot, :behaviour)

    if old_env[:firmware_handler] == Farmbot.Firmware.StubHandler do
      new_env = Keyword.put(old_env, :firmware_handler, Farmbot.Firmware.UartHandler)
      Application.put_env(:farmbot, :behaviour, new_env)
      if Process.whereis(Farmbot.Firmware) do
        GenServer.stop(Farmbot.Firmware, :shutdown)
      end
    end
  end

  defp handle_uevent(_action), do: :ok
end
