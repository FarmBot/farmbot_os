defmodule Farmbot.Bootstrap.Authorization do
  @moduledoc "Functionality responsible for getting a JWT."

  @typedoc "Email used to configure this bot."
  @type email :: binary

  @typedoc "Password used to configure this bot."
  @type password :: binary

  @typedoc "Server used to configure this bot."
  @type server :: binary

  @typedoc "Token that was fetched with the credentials."
  @type token :: binary

  alias Farmbot.Bootstrap.Authorization.Error

  @doc """
  Callback for an authorization implementation.
  Should return {:ok, token} | {:error, term}
  """
  @callback authorize(email, password, server) :: {:ok, token} | {:error, term}

  # this is the default authorize implementation.
  # It gets overwrote in the Test Environment.
  @doc "Authorizes with the farmbot api."
  def authorize(email, password, server) do
    {:ok, {_http_ver, _head, body}} = :httpc.request('#{server}/api/public_key')
    key = RSA.decode_key("#{body}")
    secret = %{email: email, password: password, id: UUID.uuid1, version: 1} |> Poison.encode! |> RSA.encrypt({:public, key}) |> Base.encode64
    payload = %{user:  %{credentials: secret}} |> Poison.encode!
    request = {'#{server}/api/tokens', ['UserAgent', 'FarmbotOSBootstrap'], 'application/json', payload}
    {:ok, {_, _, resp}} = :httpc.request(:post, request, [], [])
    {:ok, Poison.decode!(resp)["token"]["encoded"]}
  end
end
