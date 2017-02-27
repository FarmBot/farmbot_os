defmodule Farmbot.HTTP do
  @moduledoc """
    Shortcuts to Http Client because im Lazy.
  """
  alias Farmbot.Auth
  alias Farmbot.Token
  use HTTPoison.Base
  require Logger

  @version Mix.Project.config[:version]
  @target Mix.Project.config[:target]
  @ssl_hack [{:versions, [:'tlsv1.2']}]

  @type http_resp :: HTTPoison.Response.t | {:error, HTTPoison.ErrorResponse.t}

  def process_url(url) do
    {:ok, server} = fetch_server()
    server <> url
  end

  def process_request_headers(_headers) do
    {:ok, auth_headers} = build_auth()
    auth_headers
  end

  def process_request_options(opts),
    do: opts
        |> Keyword.put(:ssl, @ssl_hack)
        |> Keyword.put(:follow_redirect, true)

  def process_status_code(401) do
    Logger.info ">> Token is expired!"
    Farmbot.Auth.try_log_in
    401
  end

  def process_status_code(code), do: code

  @spec build_auth :: {:ok, [any]} | {:error, :no_token}
  defp build_auth do
    with {:ok, %Token{} = token} <- Auth.get_token
    do
      {:ok,
        ["Content-Type": "application/json",
         "User-Agent": "FarmbotOS/#{@version} (#{@target}) #{@target} ()",
         "Authorization": "Bearer " <> token.encoded]}
    else
      _ -> {:error, :no_token}
    end
  end

  @spec fetch_server :: {:error, :no_server} | {:ok, binary}
  defp fetch_server do
    case Auth.get_server do
      {:ok, nil} -> {:error, :no_server}
      {:ok, server} -> {:ok, server}
    end
  end

  @doc """
    Uploads a file to google storage
  """
  @spec upload_file(binary) :: {:ok, map} | {:error, term}
  def upload_file(file_name) do
    with {:ok, resp} <- get("/api/storage_auth"),
         {:ok, file} <- File.read(file_name)
    do
      body = Poison.decode!(resp.body)
      url = "https:" <> body["url"]
      form_data = body["form_data"]
      attachment_url = url <> form_data["key"]
      headers = [
        {"Content-Type", "multipart/form-data"},
        {"User-Agent", "FarmbotOS"}
      ]
      payload =
        Enum.map(form_data, fn({key, value}) ->
          if key == "file", do: {"file", file}, else:  {key, value}
        end)
      Logger.info ">> #{attachment_url} Should hopefully exist shortly!"
      url
      |> HTTPoison.post({:multipart, payload}, headers)
      |> finish_upload(attachment_url)
    end
  end

  @spec finish_upload({:ok, HTTPoison.Response.t} |
    {:error, HTTPoison.Error.t}, binary)
    :: {:ok, HTTPoison.Response.t} | {:error, any}

  # We only want to upload if we get a 2XX response.
  defp finish_upload({:ok, %HTTPoison.Response{status_code: s}}, attachment_url)
  when s < 300 do
    [x, y, z] = Farmbot.BotState.get_current_pos
    meta = %{x: x, y: y, z: z}
    json = Poison.encode! %{"attachment_url" => attachment_url, "meta" => meta}
    Farmbot.HTTP.post "/api/images", json
  end

  # This is just to strip the struct out of the error.
  defp finish_upload({:error, %HTTPoison.Error{reason: reason}}, aurl),
    do: finish_upload({:error, reason}, aurl)

  defp finish_upload({:error, reason}, _attachment_url) do
    Logger.error(">> Could not upload file!: #{inspect reason}")
    {:error, reason}
  end
end
