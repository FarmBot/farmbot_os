defmodule Farmbot.FarmwareRuntime.PipeWorker do
  @moduledoc """
  Proxy for IO operations.
  """
  use GenServer
  require Logger

  def start_link(pipe_name) do
    GenServer.start_link(__MODULE__, pipe_name)
  end

  def close(pipe) do
    GenServer.stop(pipe, :normal)
  end

  def read(pipe, size) do
    GenServer.call(pipe, {:read, size}, :infinity)
  end

  def write(pipe, packet) do
    GenServer.call(pipe, {:write, packet}, :infinity)
  end

  def init(pipe_name) do
    with {_, 0} <- System.cmd("mkfifo", [pipe_name]),
         {:ok, pipe} <- :file.open(to_charlist(pipe_name), [:read, :write, :binary, :raw]) do
      {:ok, %{pipe_name: pipe_name, pipe: pipe, ref: nil}}
    else
      {:error, _} = error -> {:stop, error}
      {_, _num} -> {:stop, {:error, "mkfifo"}}
    end
  end

  def terminate(_, state) do
    Logger.warn("PipeWorker #{state.pipe_name} exit")
    :file.close(state.pipe)
    File.rm!(state.pipe_name)
  end

  def handle_call({cmd, args}, {pid, _} = _from, state) do
    ref = make_ref()
    {:reply, ref, %{state | ref: ref}, {:continue, {pid, {cmd, args}}}}
  end

  def handle_continue({pid, {:read, size}}, state) do
    result = :file.read(state.pipe, size)
    send(pid, {__MODULE__, state.ref, result})
    {:noreply, %{state | ref: nil}}
  end

  def handle_continue({pid, {:write, packet}}, state) do
    result = :file.write(state.pipe, packet)
    send(pid, {__MODULE__, state.ref, result})
    {:noreply, %{state | ref: nil}}
  end
end
