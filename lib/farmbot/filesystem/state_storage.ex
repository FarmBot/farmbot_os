defmodule Farmbot.FileSystem.StateStorage do
  @moduledoc """
    Saves state that cant easily be represented as Key/Value sets
    or isn't necessisarily "configuration".
  """
  use GenServer
  require Logger

  def start_link(), do: start_link([])
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

end
