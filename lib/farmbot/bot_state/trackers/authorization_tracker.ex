defmodule Farmbot.BotState.Authorization do
  @moduledoc """
    Tracks authorization state.
  """
  require Logger
  alias Farmbot.Auth
  alias Farmbot.StateTracker
  @behaviour StateTracker
  use StateTracker,
    name: __MODULE__,
    model: [
      token: nil,
      secret: nil,
      server: nil,
      interim: nil
    ]

  def load(_) do
    with {:ok, server} <- get_config(:server),
         {:ok, secret} <- get_config(:secret)
         do
           {:ok, %State{secret: secret, server: server}}
         else
           _ -> {:ok, %State{}}
         end
  end

  @spec maybe_get_token(State.t, {:ok, Token.t} | nil) :: State.t
  defp maybe_get_token(%State{} = state, nil), do: %State{state| token: nil}
  defp maybe_get_token(%State{} = state, {:ok, token}) do
    %State{state | token: Token.create!(token)}
  end

  # Gets the server
  def handle_call(:get_server, _from, %State{} = state),
    do: dispatch state.server, state

  def handle_call(:get_token, _from, %State{} = state),
    do: dispatch state.token, state

  def handle_call(event, _from, %State{} = state) do
    Logger.error ">> got an unhandled call in Auth tracker: #{inspect event}"
    dispatch :unhandled, state
  end

  # TODO i don't really like this.
  def handle_cast(:try_log_in, %State{} = state), do: dispatch try_log_in(state)

  # We have to store these temporarily in case the bot doesnt have network yet.
  def handle_cast({:creds, {email, pass, server}}, %State{} = _state) do
    new_state =
      %State{server: server, interim: %{email: email, pass: pass}}
    dispatch new_state
  end

  def handle_cast(event, %State{} = state) do
    Logger.error ">> got an unhandled cast in Auth tracker: #{inspect event}"
    dispatch state
  end

  # this is pretty much only for testing.
  def handle_info({:authorization, %Token{} = token}, %State{} = state) do
    new_state =
      %State{state | token: token}
    dispatch new_state
  end

  @spec try_log_in(State.t) :: {:ok, Token.t} | {:error, atom}
  # If we are in "interim" state.
  # (IE: we have an email and password, but don't have a secret yet)
  # This happens on first login.
  defp try_log_in(%State{server: server, interim: %{email: email, pass: pass}})
  do
    with {:ok, pub_key} <- Auth.get_public_key(server), # Get the pub key.
         {:ok, secret}  <- Auth.encrypt(email, pass, pub_key), # build a secret.
          do: try_get_token(server, secret) # get a token.
  end

  # If we have a secret and a server, just use that.
  defp try_log_in(%State{server: server, secret: secret}),
   do: try_get_token(server, secret)

  # Tries to get a token.
  @spec try_get_token(binary, binary) :: State.t | {:error, atom}
  defp try_get_token(server, secret) do
    case Auth.get_token_from_server(secret, server) do
      {:ok, token} ->
        new_state =
          %State{server: server, secret: secret,
                 token: Token.create!(token), interim: nil}
        Logger.debug ">> authorized successfully!"
        # TODO: Need to save the secret and server in a configuration file.
        new_state
      {:error, reason} ->
        Logger.error ">> failed to authorize: #{inspect reason}"
        {:error, reason}
    end
  end
end
