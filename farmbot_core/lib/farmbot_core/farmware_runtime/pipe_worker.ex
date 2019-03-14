defmodule FarmbotCore.FarmwareRuntime.PipeWorker do
  @moduledoc """
  Proxy for Pipe IO operations.
  """
  use GenServer
  require Logger

  @read_time 5

  def start_link(pipe_name) do
    GenServer.start_link(__MODULE__, [pipe_name])
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

  def init([pipe_name]) do
    with {_, 0} <- System.cmd("mkfifo", [pipe_name]),
         pipe <- :erlang.open_port(to_charlist(pipe_name), [:eof, :binary]) do
      {:ok, %{pipe_name: pipe_name, pipe: pipe, buffer: <<>>, caller: nil, size: nil}}
    else
      {:error, _} = error -> {:stop, error}
      {_, _num} -> {:stop, {:error, "mkfifo"}}
    end
  end

  def terminate(_, state) do
    Logger.warn("PipeWorker #{state.pipe_name} exit")
    :erlang.port_close(state.pipe)
    File.rm!(state.pipe_name)
  end

  def handle_call({:write, packet}, _from, state) do
    reply = :erlang.port_command(state.pipe, packet)
    {:reply, reply, state}
  end

  def handle_call({:read, amnt}, {_pid, ref} = from, %{caller: nil, size: nil} = state) do
    Logger.debug "requesting: #{amnt} bytes"
    Process.send_after(self(), {:read, amnt, from}, @read_time)
    Process.send_after(self(), {:timeout, amnt, from}, 5000)
    {:reply, ref, %{state | caller: from, size: amnt}}
  end

  def handle_info({:timeout, size, {pid, ref}}, %{caller: {pid, ref}} = state) do
    Logger.error "Timed out waiting on #{size} bytes."
    {:stop, :timeout, state}
  end

  def handle_info({:timeout, _size, _caller}, state) do
    Logger.warn "stray timeout"
    {:noreply, state}
  end

  def handle_info({pipe, {:data, data}}, %{pipe: pipe, buffer: buffer} = state) do
    Logger.debug "bufferring #{byte_size(data)} bytes"
    {:noreply, %{state | buffer: buffer <> data}}
  end

  def handle_info({:read, size, caller}, %{buffer: buffer} = state) when byte_size(buffer) >= size do
    {pid, ref} = caller
    {resp, buffer} = String.split_at(buffer, size)
    send(pid, {__MODULE__, ref, {:ok, resp}})
    Logger.debug "pipe worker read #{size} bytes successfully #{byte_size(buffer)} bytes remaining in buffer."
    {:noreply, %{state | buffer: buffer, size: nil, caller: nil}}
  end

  def handle_info({:read, size, caller}, %{buffer: buffer} = state) when byte_size(buffer) < size do
    if byte_size(buffer) != 0 do
      Logger.debug "pipe worker still waiting on #{size - byte_size(buffer)} bytes for #{inspect(caller)} Currently #{byte_size(buffer)} bytes in buffer"
    end
    Process.send_after(self(), {:read, size, caller}, @read_time)
    {:noreply, state}
  end
end
