defmodule Farmbot.System.Updates.FwupStream do
  use GenServer
  require Logger

  @moduledoc false

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def send_chunk(pid, chunk) do
    GenServer.call(pid, {:send, chunk})
  end

  def init([]) do
    fwup = System.find_executable("fwup")
    devpath = Nerves.Runtime.KV.get("nerves_fw_devpath") || "/dev/mmcblk0"
    task = "upgrade"

    args = if supports_handshake(), do: ["--exit-handshake"], else: []
    args = args ++ ["--apply", "--no-unmount", "-d", devpath, "--task", task]

    port =
      Port.open({:spawn_executable, fwup}, [
        {:args, args},
        :use_stdio,
        :binary,
        :exit_status
      ])

    {:ok, %{port: port}}
  end

  def handle_call(_cmd, _from, %{port: nil} = state) do
    # In the process of closing down, so just ignore these.
    {:reply, :error, state}
  end

  def handle_call({:send, chunk}, _from, state) do
    # Since fwup may be slower than ssh, we need to provide backpressure
    # here. It's tricky since `Port.command/2` is the only way to send
    # bytes to fwup synchronously, but it's possible for fwup to error
    # out when it's sending. If fwup errors out, then we need to make
    # sure that a message gets back to the user for what happened.
    # `Port.command/2` exits on error (it will be an :epipe error).
    # Therefore we start a new process to call `Port.command/2` while
    # we continue to handle responses. We also trap_exit to get messages
    # when the port the Task exit.
    result =
      try do
        Port.command(state.port, chunk)
        :ok
      rescue
        ArgumentError ->
          Logger.info("Port.command ArgumentError race condition detected and handled")
          :error
      end

    {:reply, result, state}
  end

  def handle_info({port, {:data, response}}, %{port: port} = state) do
    _trimmed_response =
      if String.contains?(response, "\x1a") do
        # fwup says that it's going to exit by sending a CTRL+Z (0x1a)
        # The CTRL+Z is the very last character that will ever be
        # received over the port, so handshake by closing the port.
        send(port, {self(), :close})
        String.trim_trailing(response, "\x1a")
      else
        response
      end

    {:noreply, state}
  end

  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.info("fwup exited with status #{status} without handshaking")
    {:noreply, %{state | port: nil}}
  end

  def handle_info({port, :closed}, %{port: port} = state) do
    Logger.info("fwup port was closed")
    {:noreply, %{state | port: nil}}
  end

  defp supports_handshake() do
    Version.match?(fwup_version(), "> 0.17.0")
  end

  defp fwup_version() do
    {version_str, 0} = System.cmd("fwup", ["--version"])
    version_str
    |> String.trim()
    |> Version.parse!()
  end
end
