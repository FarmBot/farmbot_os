defmodule Farmbot.Target.ConfigMigration.AfterNetwork do
  @moduledoc "Finish the migration. Before authorization but after network."

  use GenServer
  alias Farmbot.System.ConfigStorage
  use Farmbot.Logger

  @data_path Application.get_env(:farmbot, :data_path)

  @doc false
  def start_link(_, _) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    old_config_json_file = Path.join(@data_path, "config.json")
    backup_config_json_file = Path.join(@data_path, "old_config.json")
    if File.exists?(old_config_json_file) do
      server = ConfigStorage.get_config_value(:string, "authorization", "server")
      secret = ConfigStorage.get_config_value(:string, "authorization", "password")
      case authorize(server, secret) do
        {:ok, encoded} when is_binary(encoded) ->
          {:ok, %{interim_email: email}} = Farmbot.Jwt.decode(encoded)
          ConfigStorage.update_config_value(:string, "authorization", "token", encoded)
          ConfigStorage.update_config_value(:string, "authorization", "email", email)
          Logger.success 1, "Successfully migrated secret."
          File.cp(old_config_json_file, backup_config_json_file)
          File.rm(old_config_json_file)
          :ignore
        {:error, reason} ->
          {:stop, reason}
      end
    else
      :ignore
    end
  end

  def authorize(server, secret) do
    with {:ok, payload} <- build_payload(secret),
         {:ok, resp}    <- request_token(server, payload),
         {:ok, body}    <- Poison.decode(resp),
         {:ok, map}     <- Map.fetch(body, "token") do
      Map.fetch(map, "encoded")
    else
      :error -> {:error, "unknown error."}
      {:error, :invalid, _} -> authorize(server, secret)
      # If we got maintance mode, a 5xx error etc, just sleep for a few seconds
      # and try again.
      {:ok, {{_, code, _}, _, _}} ->
        Logger.error 1, "Failed to authorize due to server error: #{code}"
        Process.sleep(5000)
        authorize(server, secret)
      err -> err
    end
  end

  defp build_payload(secret) do
    user = %{credentials: secret |> :base64.encode_to_string |> to_string}
    Poison.encode(%{user: user})
  end

  defp request_token(server, payload) do
    request = {
      '#{server}/api/tokens',
      ['UserAgent', 'FarmbotOSBootstrap'],
      'application/json',
      payload
    }

    case :httpc.request(:post, request, [], []) do
      {:ok, {{_, 200, _}, _, resp}} ->
        {:ok, resp}

      # if the error is a 4xx code, it was a failed auth.
      {:ok, {{_, code, _}, _, resp}} when code > 399 and code < 500 ->
        {
          :error,
          "Failed to authorize with the Farmbot web application at: #{server} with code: #{code}: #{inspect resp}"
        }

      # if the error is not 2xx and not 4xx, probably maintance mode.
      {:ok, _} = err -> err
      {:error, error} -> {:error, error}
    end
  end
end
