defmodule Farmbot.Configurator.WebPack do
  @moduledoc """
    This shouldnt' exist in production. Starts a webpack watch session.
  """
  require Logger
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Logger.debug("Starting webpack")
    port = Port.open({:spawn, "npm run watch"},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout])
   {:ok, port}
  end

  def handle_info({_, {:data, data}}, port) do
    IO.puts data
    {:noreply, port}
  end

  def handle_info(stuff, port) do
    IO.puts "unhandled stuff: #{inspect stuff}"
    {:noreply, port}
  end
end
