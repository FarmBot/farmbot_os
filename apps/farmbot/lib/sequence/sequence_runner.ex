defmodule SequenceRunner do
  @moduledoc """
    Runs a Sequence
  """
  use GenServer
  require Logger
  def start_link(sequence, time) do
    GenServer.start_link(__MODULE__, [sequence, time])
  end

  def init([sequence, time]) do
    Logger.debug "running a sequence: #{sequence.name}"
    {:ok, []}
  end
end
