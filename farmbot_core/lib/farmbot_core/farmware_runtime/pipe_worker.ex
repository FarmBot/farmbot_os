defmodule FarmbotCore.FarmwareRuntime.PipeWorker do
  @moduledoc """
  Proxy for Pipe IO operations.
  """
  use GenServer
  require Logger

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
    {:reply, ref, %{state | caller: from, size: amnt, buffer: nil}, {:continue, state.buffer}}
  end

  def handle_info({pipe, {:data, data}}, %{pipe: pipe, buffer: buffer} = state) do
    buffer = buffer <> data
    {:noreply, %{state | buffer: nil}, {:continue, buffer}}
  end

  def handle_continue(buffer, %{size: size} = state) when byte_size(buffer) >= size do
    {pid, ref} = state.caller
    {resp, buffer} = String.split_at(buffer, size)
    send(pid, {__MODULE__, ref, {:ok, resp}})
    {:noreply, %{state | caller: nil, size: nil, buffer: buffer}}
  end

  def handle_continue(buffer, state) do
    {:noreply, %{state | buffer: buffer}}
  end
end
