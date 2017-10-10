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

  @doc """
  Callback for an authorization implementation.
  Should return {:ok, token} | {:error, term}
  """
  @callback authorize(email, password, server) :: {:ok, token} | {:error, term}

  # this is the default authorize implementation.
  # It gets overwrote in the Test Environment.
  @doc "Authorizes with the farmbot api."
  def authorize(email, password, server) do
    with {:ok, rsa_key } <- fetch_rsa_key(server),
         {:ok, payload } <- build_payload(email, password, rsa_key),
         {:ok, resp    } <- request_token(server, payload),
         {:ok, body    } <- Poison.decode(resp),
         {:ok, map     } <- Map.fetch(body, "token") do
           Map.fetch(map,  "encoded")
         else
           :error -> {:error, "unknown error."}
           err ->
             require IEx; IEx.pry
             err
         end
  end

  defp fetch_rsa_key(server) do
    case :httpc.request('#{server}/api/public_key') do
      {:ok, {_, _, body}} ->
        r = body |> to_string() |> RSA.decode_key()
        {:ok, r}
      {:error, error} -> {:error, error}
    end
  end

  defp build_payload(email, password, rsa_key) do
    secret = %{email: email, password: password, id: UUID.uuid1, version: 1}
    |> Poison.encode!
    |> RSA.encrypt({:public, rsa_key})
    |> Base.encode64
    %{user:  %{credentials: secret}} |> Poison.encode
  end

  defp request_token(server, payload) do
    request = {'#{server}/api/tokens',
               ['UserAgent', 'FarmbotOSBootstrap'],
               'application/json', payload}

    case :httpc.request(:post, request, [], []) do
      {:ok, {{_, 200, _}, _, resp  }} -> {:ok, resp}
      {:ok, {{_, code, _}, _, _resp }} ->
        {:error, "Failed to authorize with the Farmbot web application at: #{server} with code: #{code}"}
      {:error, error} -> {:error, error}
    end

  end
end
