defmodule FarmbotOS.Bootstrap.Authorization do
  @moduledoc "Functionality responsible for getting a JWT."

  @typedoc "Email used to configure this bot."
  @type email :: String.t()

  @typedoc "Password used to configure this bot."
  @type password :: binary

  @typedoc "Password hash."
  @type secret :: binary

  @typedoc "Server used to configure this bot."
  @type server :: String.t()

  @typedoc "Token that was fetched with the credentials."
  @type token :: binary

  require FarmbotOS.Logger

  alias FarmbotOS.{JSON, Project}

  @version Project.version()
  @target Project.target()

  @spec authorize_with_secret(email, secret, server) ::
          {:ok, binary} | {:error, String.t() | atom}
  def authorize_with_secret(_email, secret, server) do
    with {:ok, payload} <- build_payload(secret),
         {:ok, resp} <- request_token(server, payload),
         {:ok, body} <- JSON.decode(resp) do
      get_encoded(body)
    end
  end

  @spec authorize_with_password(email, password, server) ::
          {:ok, binary} | {:error, String.t() | atom}
  def authorize_with_password(email, password, server) do
    with {:ok, {:RSAPublicKey, _, _} = rsa_key} <- fetch_rsa_key(server),
         {:ok, payload} <- build_payload(email, password, rsa_key),
         {:ok, resp} <- request_token(server, payload),
         {:ok, body} <- JSON.decode(resp) do
      get_encoded(body)
    end
  end

  @doc "Helper function that returns the secret after a successful request"
  def authorize_with_password_v2(email, password, server) do
    with {:ok, {:RSAPublicKey, _, _} = rsa_key} <- fetch_rsa_key(server),
         secret <- build_secret(email, password, rsa_key),
         {:ok, payload} <- build_payload(email, password, rsa_key),
         {:ok, resp} <- request_token(server, payload),
         {:ok, body} <- JSON.decode(resp),
         {:ok, encoded} <- get_encoded(body) do
      {:ok, {encoded, secret}}
    end
  end

  defp get_encoded(%{"token" => %{"encoded" => encoded}}), do: {:ok, encoded}
  defp get_encoded(_), do: {:error, :bad_response}

  def build_payload(email, password, rsa_key) do
    build_secret(email, password, rsa_key)
    |> build_payload()
  end

  def build_payload(secret) do
    %{user: %{credentials: secret |> Base.encode64()}}
    |> JSON.encode()
  end

  def build_secret(email, password, rsa_key) do
    %{email: email, password: password, id: UUID.uuid1(), version: 1}
    |> JSON.encode!()
    |> rsa_encrypt({:public, rsa_key})
  end

  @headers [
    {"User-Agent", "FarmbotOS/#{@version} (#{@target}) #{@target} ()"},
    {"Content-Type", "application/json"}
  ]

  @spec fetch_rsa_key(server) :: {:ok, term} | {:error, String.t() | atom}
  def fetch_rsa_key(server) when is_binary(server) do
    url = "#{server}/api/public_key"

    with {:ok, body} <- do_request({:get, url, "", @headers}) do
      {:ok, rsa_decode_key(body)}
    end
  end

  @spec request_token(server, binary) ::
          {:ok, binary} | {:error, String.t() | atom}
  def request_token(server, payload, tries_remaining \\ 10) do
    url = "#{server}/api/tokens"

    case do_request({:post, url, payload, @headers}) do
      # Don't try more times if we have an ok request.
      {:ok, _} = ok ->
        ok

      # Don't try more times if there was a 4xx error
      {:error, {:authorization, reason}} ->
        {:error, reason}

      # Network error such such as wifi disconnect, dns down etc.
      # Try again.
      {:error, reason} when tries_remaining == 0 ->
        FarmbotOS.Logger.error(
          1,
          "Farmbot failed to request token: #{inspect(reason)}"
        )

        {:error, reason}

      {:error, _reason} ->
        FarmbotOS.Time.sleep(2500)
        request_token(server, payload, tries_remaining - 1)
    end
  end

  def do_request(request, state \\ %{backoff: 5000, log_dispatch_flag: false})

  def do_request({method, url, payload, headers}, state) do
    headers =
      Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)

    opts = [{:body_format, :binary}]

    request =
      if method == :get,
        do: {to_charlist(url), headers},
        else: {to_charlist(url), headers, 'Application/JSON', payload}

    resp = FarmbotOS.HTTP.request(method, request, [], opts)

    case resp do
      {:ok, {{_, c, _}, _headers, body}} when c >= 200 and c <= 299 ->
        {:ok, body}

      {:ok, {{_, c, _}, _headers, body}} when c >= 400 and c <= 499 ->
        err = get_error_message(body)

        FarmbotOS.Logger.error(
          1,
          "Authorization error for url: #{url} #{err}"
        )

        {:error, {:authorization, err}}

      {:ok, {{_, c, _}, _headers, body}} when c >= 500 and c <= 599 ->
        FarmbotOS.Time.sleep(state.backoff)

        unless state.log_dispatch_flag do
          err = get_error_message(body)

          FarmbotOS.Logger.warn(
            1,
            "Farmbot web app failed complete request for url: #{url} #{err}"
          )
        end

        do_request({method, url, payload, headers}, %{
          state
          | backoff: state.backoff + 1000,
            log_dispatch_flag: true
        })

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec get_error_message(binary) :: String.t()
  defp get_error_message(bin) when is_binary(bin) do
    case JSON.decode(bin) do
      {:ok, %{"auth" => reason}} when is_binary(reason) -> reason
      _ -> bin
    end
  end

  # Encrypt using the public key
  def rsa_encrypt(text, {:public, key}) do
    text |> :public_key.encrypt_public(key)
  end

  # Decode a key from its text representation to a PEM structure
  def rsa_decode_key(text) do
    [entry] = :public_key.pem_decode(text)
    :public_key.pem_entry_decode(entry)
  end

  # ONLY NEEDED FOR TESTS AND VERIFICATION.
  # Decrypt using the private key
  def rsa_decrypt(cyphertext, {:private, key}) do
    cyphertext |> :public_key.decrypt_private(key)
  end
end
