defmodule Farmbot.Configurator.Logger do
  @moduledoc """
    Tiny logger backend to broadcast relevent logs to a connected configurator.
  """
  alias Farmbot.Configurator.EventManager, as: EM
  use GenEvent
  def init(args), do: {:ok, args}
  def handle_event({_l, _f, {Logger, ">>" <> message, _ts, _meta}}, socket) do
    m = %{method: "log_message", id: nil, params: [%{message: "farmbot #{message}"}]}
    |> Poison.encode!
    |> broadcast
    {:ok, socket}
  end

  def handle_event(_, socket), do: {:ok, socket}
  def broadcast(message) when is_binary(message) do
    EM.send_socket({:from_bot, message})
  end
end
