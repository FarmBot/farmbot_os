defmodule FarmbotOS.FarmwareRuntime.PipeWorker do
  @moduledoc """
  Proxy for Pipe IO operations.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: State

  defstruct [
    :port,
    :pipe_name,
    :pipe,
    :buffer,
    :caller,
    :size,
    :timeout_timer,
    :direction
  ]

  @read_time 5

  def start_link(pipe_name, direction) do
    GenServer.start_link(__MODULE__, [pipe_name, direction])
  end

  def close(pipe) do
    GenServer.stop(pipe, :normal)
  end

  def read(pipe, amnt) do
    GenServer.call(pipe, {:read, amnt})
  end

  def write(pipe, packet) do
    GenServer.call(pipe, {:write, packet}, :infinity)
  end

  def init([pipe_name, direction]) do
    Logger.debug("opening pipe: #{pipe_name}")

    {:ok, port} =
      :gen_tcp.listen(0, [
        {:ip, {:local, to_charlist(pipe_name)}},
        {:ifaddr, {:local, to_charlist(pipe_name)}},
        :local,
        {:active, true},
        :binary
      ])

    send(self(), :accept)
    # {:ok, pipe} = :gen_tcp.accept(lsocket)
    {:ok,
     %State{
       pipe_name: pipe_name,
       port: port,
       buffer: <<>>,
       direction: direction
     }}
  end

  def terminate(_, state) do
    Logger.warning("PipeWorker #{state.direction} #{state.pipe_name} exit")
    # :erlang.port_close(state.pipe)
    state.pipe && :gen_tcp.close(state.pipe)
    File.rm!(state.pipe_name)
  end

  def handle_call({:write, packet}, _from, state) do
    Logger.debug("#{state.direction} writing #{byte_size(packet)} bytes")

    if state.pipe do
      :ok = :gen_tcp.send(state.pipe, packet)
    else
      Logger.warning("no pipe")
    end

    # reply = :erlang.port_command(state.pipe, packet)
    {:reply, true, state}
  end

  def handle_call(
        {:read, amnt},
        {_pid, ref} = from,
        %{caller: nil, size: nil} = state
      ) do
    Logger.debug("#{state.direction} requesting: #{amnt} bytes")
    Process.send_after(self(), {:read, amnt, from}, @read_time)
    # timeout_timer = Process.send_after(self(), {:timeout, amnt, from}, 5000)
    timeout_timer = nil

    {:reply, ref,
     %{state | caller: from, size: amnt, timeout_timer: timeout_timer}}
  end

  def handle_info({:tcp_closed, _port}, state) do
    send(self(), :accept)
    {:noreply, %{state | pipe: nil}}
  end

  def handle_info(:accept, state) do
    case :gen_tcp.accept(state.port, 100) do
      {:ok, pipe} ->
        {:noreply, %{state | pipe: pipe}}

      {:error, :timeout} ->
        send(self(), :accept)
        {:noreply, %{state | pipe: nil}}
    end
  end

  def handle_info({:timeout, size, {pid, ref}}, %{caller: {pid, ref}} = state) do
    Logger.error("#{state.direction} Timed out waiting on #{size} bytes.")
    {:stop, :timeout, state}
  end

  def handle_info({:timeout, _size, _caller}, state) do
    Logger.warning("stray timeout")
    {:noreply, state}
  end

  # {udp,#Port<0.676>,{127,0,0,1},8790,<<"hey there!">>}
  # def handle_info({pipe, {:data, data}}, %{pipe: pipe, buffer: buffer} = state) do
  def handle_info({:tcp, pipe, data}, %{pipe: pipe, buffer: buffer} = state) do
    Logger.debug("#{state.direction} buffering #{byte_size(data)} bytes")
    {:noreply, %{state | buffer: buffer <> data}}
  end

  def handle_info({:read, size, caller}, %{buffer: buffer} = state)
      when byte_size(buffer) >= size do
    _ = state.timeout_timer && Process.cancel_timer(state.timeout_timer)
    {pid, ref} = caller
    {resp, buffer} = String.split_at(buffer, size)
    send(pid, {__MODULE__, ref, {:ok, resp}})

    Logger.debug(
      "#{state.direction} pipe worker read #{size} bytes successfully #{byte_size(buffer)} bytes remaining in buffer."
    )

    {:noreply, %{state | buffer: buffer, size: nil, caller: nil}}
  end

  def handle_info({:read, size, caller}, %{buffer: buffer} = state)
      when byte_size(buffer) < size do
    if byte_size(buffer) != 0 do
      Logger.debug(
        "#{state.direction} pipe worker still waiting on #{size - byte_size(buffer)} bytes for #{inspect(caller)} Currently #{byte_size(buffer)} bytes in buffer"
      )
    end

    Process.send_after(self(), {:read, size, caller}, @read_time)
    {:noreply, state}
  end
end
