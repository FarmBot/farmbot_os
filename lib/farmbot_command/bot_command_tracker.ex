defmodule Command.Tracker do
  @moduledoc """
    Restarts serial stuffs when 3 commands fail in a row.
  """
  
  use GenServer
  def init(_args) do
    {:ok, 0}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # When we get a successful message, reset the counter.
  def handle_cast(:done, _) do
    {:noreply, 0}
  end

  def handle_cast(:e_stop, _) do
    {:noreply, 0}
  end

  # If the message is not successful, and count is less than three,
  # increase it.
  def handle_cast(_, count) when count < 2 do
    {:noreply, count + 1}
  end

  # If error count is greater than three, assume something is wrong.
  def handle_cast(_, _count) do
    {:crash, nil}
  end

  def handle_call(:get_state, _from, count) do
    {:reply, count, count}
  end

  @spec beep(Command.command_output) :: Command.command_output
  def beep(result) do
    GenServer.cast(__MODULE__, result)
    result
  end

  @spec get_state() :: number
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  # I don't know if this will ever match but just in case.
  def terminate(:normal, _) do
    :ok
  end

  # If the count is greater than three, we should probably try to restart
  # Serial Processes.
  def terminate(_, _) do
    GenServer.stop(Serial.Handler, :restart)
  end

end
