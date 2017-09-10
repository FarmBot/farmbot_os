defmodule Farmbot.Test.SystemTasks do
  @moduledoc "Test implementation for system tasks"
  @behaviour Farmbot.System

  # System Implementation.

  def factory_reset(reason) do
    pid = fetch_pid()
    GenServer.call(pid, {:factory_reset, reason})
  end

  def reboot(reason) do
    pid = fetch_pid()
    GenServer.call(pid, {:reboot, reason})
  end

  def shutdown(reason) do
    pid = fetch_pid()
    GenServer.call(pid, {:shutdown, reason})
  end

  # Test Helpers.

  use GenServer

  @doc "Fetches the last action and reason"
  @spec fetch_last() :: {:factory_reset | :reboot | :shutdown, any} | nil
  def fetch_last do
    pid = fetch_pid()
    GenServer.call(pid, :fetch_last)
  end

  defp fetch_pid do
    maybe_pid = Process.whereis(__MODULE__)
    if is_pid(maybe_pid) do
      maybe_pid
    else
      {:ok, pid} = GenServer.start_link(__MODULE__, [], [name: __MODULE__])
      pid
    end
  end

  def init([]) do
    {:ok, []}
  end

  def handle_call({_action, _reason} = thing, _, state) do
    {:reply, :ok, [thing | state]}
  end

  def handle_call(:fetch_last, _, [] = state) do
    {:reply, nil, state}
  end

  def handle_call(:fetch_last, _, [last | _rest] = state) do
    {:reply, last, state}
  end

end
