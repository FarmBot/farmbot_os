defmodule FarmEventManager do
  @save_interval 10000
  @log_tag "FarmEventManager"
  require Logger
  @moduledoc """
    This isn't an event manager contrary to module name.
    Long story short we called these tasks "events".
    So it should be phrased as "FarmEvent Manager"
    This module is the tracker that allows regimen_items to gracefully start sequences.
  """

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    # Process.send_after(self(), :save, @save_interval)
    {:ok, load}
  end

  def load do
    default_state = %{
      paused_regimens: [],    # [{pid, regimen, finished_items, time}]
      running_regimens: [],   # [{pid, regimen, finished_items, time}]
      current_sequence: nil,  # {pid, sequence} | nil
      paused_sequences: [] ,  # [{pid, sequence}]
      sequence_log: []        # [sequence]
    }
    default_state
  end

  def save(state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
  end

  def terminate(:normal, state) do
    Logger.debug("Farm Event Manager died. This is not good.")
    save(state)
  end

  def terminate(reason, state) do
    Logger.error("Farm Event Manager died. This is not good.")
    spawn fn -> RPCMessageHandler.send_status end
    IO.inspect reason
    IO.inspect state
  end
end
