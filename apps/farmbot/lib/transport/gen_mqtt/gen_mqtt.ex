alias Farmbot.Transport.GenMqtt.Client, as: Client
defmodule Farmbot.Transport.GenMqtt do
  @moduledoc """
    Transport for GenMqtt
  """

  # GENSTAGE HACK
  @spec handle_call(any, any, any) :: {:reply, any, any}
  @spec handle_cast(any, any) :: {:noreply, any}
  @spec handle_info(any, any) :: {:noreply, any}
  @spec init(any) :: {:ok, any}
  @spec handle_events(any, any, any) :: no_return

  use GenStage
  require Logger
  alias Farmbot.Token
  @type state :: {pid | nil, Token.t | nil}

  @doc """
    Starts the handler that watches the mqtt client
  """
  @spec start_link :: {:ok, pid}
  def start_link,
    do: GenStage.start_link(__MODULE__, {nil, nil}, name: __MODULE__)

  @spec init(state) :: {:consumer, state, subscribe_to: [Farmbot.Transport]}
  def init(initial) do
    case Farmbot.Auth.get_token do
      {:ok, %Token{} = t} ->
        {:ok, pid} = Client.start_link(t)
        {:consumer, {pid, t}, subscribe_to: [Farmbot.Transport]}
      _ ->
      {:consumer, initial, subscribe_to: [Farmbot.Transport]}
    end
  end

  def handle_events(events, _, {_client, %Token{} = _} = state) do
    for event <- events do
      Logger.info("#{__MODULE__}: Got event: #{inspect event}")
    end
    {:noreply, [], state}
  end

  def handle_info({:authorization, %Token{} = t}, {nil, _}) do
    {:ok, pid} = start_client(t)
    {:noreply, [], {pid, t}}
  end

  def handle_info({:authorization, %Token{} = new_t}, {client, _})
  when is_pid(client) do
    # Probably a good idea to restart mqtt here.
    Logger.info ">> needs to restart MQTT"
    if Process.alive?(client) do
      GenServer.stop(client, :normal)
    end
    {:ok, pid} = start_client(new_t)
    {:noreply, [], {pid,new_t}}
  end

  def handle_info({_from, event}, {client, %Token{} = _token} = state)
  when is_pid(client) do
    Client.cast(client, event)
    {:noreply, [], state}
  end

  def handle_info(_e, state) do
    # catch other messages if we don't have a token, or client or
    # we just don't know how to handle this message.
    {:noreply, [], state}
  end

  @spec start_client(Token.t) :: {:ok, pid}
  defp start_client(%Token{} = token), do: Client.start_link(token)
end
