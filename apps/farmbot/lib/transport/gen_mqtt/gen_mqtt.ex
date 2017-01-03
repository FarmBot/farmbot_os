alias Farmbot.Transport.GenMqtt.Client, as: Client
alias Experimental.GenStage
defmodule Farmbot.Transport.GenMqtt do
  use GenStage
  require Logger
  alias Farmbot.Token
  alias Farmbot.Transport.Serialized, as: Ser
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

  # GenStage callback.
  def handle_events([%Ser{} = ser], _, {client, %Token{} = _} = state)
  when is_pid(client) do
    Client.cast(client, ser)
    {:noreply, [], state}
  end

  def handle_events([{:emit, msg}], _, {client, %Token{} = _} = state)
  when is_pid(client) do
    Client.cast(client, {:emit, msg})
    {:noreply, [], state}
  end

  def handle_events([{:log, msg}], _, {client, %Token{} = _} = state)
  when is_pid(client) do
    Client.cast(client, {:log, msg})
    {:noreply, [], state}
  end

  def handle_events(_,_,state), do: {:noreply, [], state}

  def handle_info({:authorization, %Token{} = t}, {nil, _}) do
    {:ok, pid} = start_client(t)
    {:noreply, [], {pid, t}}
  end

  def handle_info({:authorization, %Token{} = t}, state) do
    {:noreply, [], state}
  end

  defp start_client(%Token{} = token), do: Client.start_link(token)
end
