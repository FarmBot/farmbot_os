alias Farmbot.Transport.GenMqtt.Client, as: Client
defmodule Farmbot.Transport.GenMqtt do
  @moduledoc """
    Transport for GenMqtt
  """

  use GenStage
  require Logger
  alias Farmbot.Token
  alias Farmbot.CeleryScript.Ast.Context

  @type state :: {pid | nil, Token.t | nil}

  @doc """
    Starts the handler that watches the mqtt client
  """
  @spec start_link(Context.t, [{atom, any}]) :: {:ok, pid}
  def start_link(context, opts \\ []),
    do: GenStage.start_link(__MODULE__, {nil, nil, context}, opts)

  @spec init(state) :: {:consumer, state, subscribe_to: [Farmbot.Transport]}
  def init(initial) do
    {_, _, context} = initial
    Registry.register(Farmbot.Registry, Farmbot.Auth, [])
    case Farmbot.Auth.get_token(context.auth) do
      {:ok, %Token{} = t} ->
        {:ok, pid} = start_client(context, t)
        {:consumer, {pid, t, context}, subscribe_to: [Farmbot.Transport]}
      _ ->
      {:consumer, initial, subscribe_to: [Farmbot.Transport]}
    end
  end

  def terminate(_reason, _state) do
    :ok
  end

  def handle_events(events, _, {_client, %Token{} = _, _context} = state) do
    for event <- events do
      Logger.info("#{__MODULE__}: Got event: #{inspect event}")
    end
    {:noreply, [], state}
  end

  def handle_info({Farmbot.Auth, {:new_token, token}}, {nil, _, context}) do
    {:ok, pid} = start_client(context, token)
    {:noreply, [], {pid, token, context}}
  end

  def handle_info({Farmbot.Auth, {:new_token, new_t}}, {client, _, context})
  when is_pid(client) do
    # Probably a good idea to restart mqtt here.
    Logger.info ">> needs to restart MQTT"
    if Process.alive?(client) do
      GenServer.stop(client, :normal)
    end
    {:ok, pid} = start_client(context, new_t)
    {:noreply, [], {pid, new_t, context}}
  end

  def handle_info({:authorization, %Token{} = new_t}, {_, _, context}) do
    {:ok, pid} = start_client(context, new_t)
    {:noreply, [], {pid, new_t, context}}
  end

  def handle_info({_from, event}, {client, %Token{} = _token, _context} = state)
  when is_pid(client) do
    Client.cast(client, event)
    {:noreply, [], state}
  end

  def handle_info(_e, state) do
    # catch other messages if we don't have a token, or client or
    # we just don't know how to handle this message.
    {:noreply, [], state}
  end

  @spec start_client(Context.t, Token.t) :: {:ok, pid}
  defp start_client(%Context{} = context, %Token{} = token) do
    {:ok, pid} = Client.start_link(context, token)
    true = Process.link(pid)
    {:ok, pid}
  end
end
