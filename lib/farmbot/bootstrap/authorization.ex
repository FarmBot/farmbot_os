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

  use Farmbot.Logger
  alias Farmbot.System.GPIO.Leds
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [update_config_value: 4, get_config_value: 3]

  @version Farmbot.Project.version()
  @target Farmbot.Project.target()
  @data_path Application.get_env(:farmbot, :data_path)

  @doc """
  Callback for an authorization implementation.
  Should return {:ok, token} | {:error, term}
  """
  @callback authorize(email, password, server) :: {:ok, token} | {:error, term}

  # this is the default authorize implementation.
  # It gets overwrote in the Test Environment.
  @doc "Authorizes with the farmbot api."
  def authorize(email, pw_or_secret, server) do
    case get_config_value(:bool, "settings", "first_boot") do
      false -> authorize_with_secret(email, pw_or_secret, server)
      true -> authorize_with_password(email, pw_or_secret, server)
    end
    |> case do
      {:ok, token} -> {:ok, token}
      err ->
        Logger.error 1, "Authorization failed: #{inspect err}"
        err
    end
  end

  def authorize_with_secret(email, secret, server) do
    with {:ok, payload} <- build_payload(secret),
         {:ok, resp}    <- request_token(server, payload),
         {:ok, body}    <- Poison.decode(resp),
         {:ok, map}     <- Map.fetch(body, "token") do
      Leds.led_status_ok()
      last_reset_reason_file = Path.join(@data_path, "last_shutdown_reason")
      File.rm(last_reset_reason_file)
      Map.fetch(map, "encoded")
    else
      :error -> {:error, "unknown error."}
      {:error, :invalid, _} -> authorize(email, secret, server)
      # If we got maintance mode, a 5xx error etc,
      # just sleep for a few seconds
      # and try again.
      {:error, {:http_error, code}} ->
        Logger.error 1, "Failed to authorize due to server error: #{code}"
        Process.sleep(5000)
        authorize(email, secret, server)
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      err -> err
    end
  end

  def authorize_with_password(email, password, server) do
    with {:ok, {:RSAPublicKey, _, _} = rsa_key} <- fetch_rsa_key(server),
         {:ok, payload} <- build_payload(email, password, rsa_key),
         {:ok, resp}    <- request_token(server, payload),
         {:ok, body}    <- Poison.decode(resp),
         {:ok, map}     <- Map.fetch(body, "token") do
      update_config_value(:bool, "settings", "first_boot", false)
      last_reset_reason_file = Path.join(@data_path, "last_shutdown_reason")
      File.rm(last_reset_reason_file)
      Leds.led_status_ok()
      Map.fetch(map, "encoded")
    else
      :error -> {:error, "unknown error."}
      {:error, :invalid, _} -> authorize(email, password, server)
      # If we got maintance mode, a 5xx error etc,
      # just sleep for a few seconds
      # and try again.
      {:error, {:http_error, code}} when code >= 500 or code < 600 ->
        Logger.error 2, "Failed to authorize due to server error: #{code}"
        Process.sleep(5000)
        authorize(email, password, server)
      {:error, {:http_error, code}} ->
        Logger.error 1, "Failed to authorize due to server error: #{code}"
        Process.sleep(5000)
        authorize(email, password, server)
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      err -> err
    end
  end

  def fetch_rsa_key(server) do
    url = "#{server}/api/public_key"
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        r = body |> to_string() |> RSA.decode_key()
        {:ok, r}
      {:ok, %{status_code: code, body: body}} ->
        msg = """
        Failed to fetch public key.
        status_code: #{code}
        body: #{inspect body}
        """
        {:error, msg}
      {:error, reason} -> {:error, reason}
    end
  end

  def build_payload(email, password, rsa_key) do
    secret =
      %{email: email, password: password, id: UUID.uuid1(), version: 1}
      |> Poison.encode!()
      |> RSA.encrypt({:public, rsa_key})
    update_config_value(:string, "authorization", "password", secret)
    %{user: %{credentials: secret |> Base.encode64()}} |> Poison.encode()
  end

  defp build_payload(secret) do
    user = %{credentials: secret |> :base64.encode_to_string |> to_string}
    Poison.encode(%{user: user})
  end

  def request_token(server, payload) do
    headers = [
      {"User-Agent", "FarmbotOS/#{@version} (#{@target}) #{@target} ()"},
      {"Content-Type", "application/json"}
    ]
    case HTTPoison.post("#{server}/api/tokens", payload, headers) do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}

      # if the error is a 4xx code, it was a failed auth.
      {:ok, %{status_code: code, body: body}} when code > 399 and code < 500 ->
        reason = get_body(body)
        msg = """
        Failed to authorize with the Farmbot web application at: #{server}
        with code: #{code}
        body: #{reason}
        """
        {:error, msg}

      # if the error is not 2xx and not 4xx, probably maintance mode.
      {:ok, %{status_code: code}} -> {:error, {:http_error, code}}
      {:error, error} -> {:error, error}
    end
  end

  defp get_body(body) do
    case Poison.decode(body) do
      {:ok, %{"auth" => reason}} -> reason
      {:ok, reason} -> inspect reason
      _ -> inspect body
    end
  end
end
