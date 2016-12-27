defmodule WebPack do
  require Logger
  use GenServer

  def start_link(env) do
    GenServer.start_link(__MODULE__, env, name: __MODULE__)
  end

  def init(:prod), do: {:ok, spawn fn() -> nil end}
  def init(:dev) do
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
