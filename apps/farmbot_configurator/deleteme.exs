defmodule ERM do
  use GenEvent
  alias Farmbot.Configurator.EventManager, as: EM
  require Logger
  def start do
    GenEvent.add_handler(EM, __MODULE__, [])
  end

  def stop do
    GenEvent.remove_handler(EM, __MODULE__, [])
  end

  def init(_) do
    {:ok, []}
  end

  def handle_event( {:from_socket, %{"id" => id, "method" => "hey_bot", "params" => []}}, state) do
    thing = %{id: id, results: "hey_front_end", error: nil} |> Poison.encode!
    Logger.debug thing
    EM.send_socket({:from_bot, thing})
    {:ok, state}
  end


  def handle_event({:from_socket, rpc}, state) do
    Logger.debug "Got rpc: #{inspect rpc}"
    {:ok, state}
  end

  def handle_event(_,s) do
    {:ok, s}
  end
end
