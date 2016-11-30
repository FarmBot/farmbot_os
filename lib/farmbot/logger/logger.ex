defmodule Farmbot.Logger do
  use GenServer
  @moduledoc """
    Right now this doesn't do anything but eventually it will save log messages
    and push them to teh frontend
  """
  def log(message, channels, tags) do
    Farmbot.RPC.Handler.log(message, channels, tags)
    GenServer.cast(__MODULE__, {:log, message, tags, Timex.now})
  end

  def get_all do
    GenServer.call(__MODULE__, :get_all)
  end

  def init(_args) do
    {:ok, []}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_cast({:log, message, tags, time}, messages) do
    {:noreply, [{message, tags, time} | messages]}
  end

  def handle_call(:get_all, _from, messages) do
    {:reply, Enum.reverse(messages), messages}
  end

  def handle_call({:get, ammount}, _from, messages) do
    {:reply,
    Enum.reverse(messages)
    |> Enum.take(ammount),
    messages}
  end

  def handle_call(:clear, _from, messages), do: {:reply, messages, []}
  def clear, do: GenServer.call(__MODULE__, :clear)
end
