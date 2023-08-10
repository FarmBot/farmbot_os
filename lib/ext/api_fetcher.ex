defmodule FarmbotOS.APIFetcher do
  @moduledoc """
  Provides network related function for FarmbotOS.API
  """

  use Tesla
  require FarmbotOS.Logger

  alias FarmbotOS.{BotState, BotState.JobProgress.Percent, Project}
  alias FarmbotOS.Asset.StorageAuth
  alias FarmbotOS.JSON
  alias FarmbotOS.JWT
  alias Tesla.Multipart

  import FarmbotOS.Config, only: [get_config_value: 3]

  @file_chunk 4096
  @progress_steps 50
  @target Project.target()
  @version Project.version()

  plug(Tesla.Middleware.JSON, decode: &JSON.decode/1, encode: &JSON.encode/1)
  plug(Tesla.Middleware.FollowRedirects)
  @doc "helper for `GET`ing a path."

  def get_body!(path) do
    case get(client(), path) do
      {:ok, %{status: 401}} ->
        FarmbotOS.Bootstrap.reauth()
        {:error, "Token is expired. Please try again."}

      {:ok, %{body: body, status: 200}} ->
        {:ok, body}

      {:ok, %{body: error, status: status}} when is_binary(error) ->
        get_body_error(path, status, error)

      {:ok, %{body: %{"error" => error}, status: status}}
      when is_binary(error) ->
        get_body_error(path, status, error)

      {:ok, %{body: error, status: status}} when is_binary(error) ->
        get_body_error(path, status, inspect(error))

      {:error, reason} ->
        {:error, reason}
    end
  end

  def client do
    binary_token = get_config_value(:string, "authorization", "token")
    server = get_config_value(:string, "authorization", "server")
    {:ok, _tkn} = JWT.decode(binary_token)

    uri = URI.parse(server)

    url =
      (uri.scheme || "https") <> "://" <> uri.host <> ":" <> to_string(uri.port)

    user_agent = "FarmbotOS/#{@version} (#{@target}) #{@target} ()"

    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      {Tesla.Middleware.Headers,
       [
         {"content-type", "application/json"},
         {"authorization", "Bearer: " <> binary_token},
         {"user-agent", user_agent}
       ]}
    ]

    Tesla.client(middleware, adapter())
  end

  def storage_client(%StorageAuth{url: url}) do
    server = get_config_value(:string, "authorization", "server")
    uri = URI.parse(server)
    user_agent = "FarmbotOS/#{@version} (#{@target}) #{@target} ()"

    middleware = [
      {Tesla.Middleware.BaseUrl, "#{uri.scheme}:#{url}"},
      {Tesla.Middleware.Headers,
       [
         {"user-agent", user_agent}
       ]},
      {Tesla.Middleware.FormUrlencoded, []}
    ]

    Tesla.client(middleware, adapter())
  end

  def upload_image(image_filename, meta \\ %{}) do
    # I don't like that APIFetcher calls API- refactor out?
    {:ok, changeset} = FarmbotOS.API.get_changeset(StorageAuth)

    storage_auth =
      %StorageAuth{form_data: form_data} =
      Ecto.Changeset.apply_changes(changeset)

    content_length = :filelib.file_size(image_filename)
    {:ok, pid} = Agent.start_link(fn -> 0 end)

    prog = %Percent{
      status: "Working",
      percent: 0,
      file_type: Path.extname(image_filename),
      type: :image,
      time: DateTime.utc_now()
    }

    stream =
      image_filename
      |> File.stream!([], @file_chunk)
      |> Stream.each(fn chunk ->
        Agent.update(pid, fn sent ->
          size = sent + byte_size(chunk)
          prog = put_progress(prog, size, content_length)
          BotState.set_job_progress(image_filename, prog)
          size
        end)
      end)

    opts = [filename: image_filename, headers: [{"Content-Type", "image/jpeg"}]]

    mp =
      Multipart.new()
      |> Multipart.add_field("key", form_data.key)
      |> Multipart.add_field("acl", form_data.acl)
      |> Multipart.add_field("policy", form_data.policy)
      |> Multipart.add_field("signature", form_data.signature)
      |> Multipart.add_field("Content-Type", form_data."Content-Type")
      |> Multipart.add_field("GoogleAccessId", form_data."GoogleAccessId")
      |> Multipart.add_field("file", stream, opts)

    storage_resp =
      storage_auth
      |> storage_client()
      |> request(
        method: String.to_existing_atom(String.downcase(storage_auth.verb)),
        body: mp
      )

    with {:ok, %{url: url, status: s}} when s > 199 and s < 300 <- storage_resp,
         attachment_url <- Path.join(url, form_data.key),
         client <- client(),
         body <- %{attachment_url: attachment_url, meta: meta},
         {:ok, %{status: s}} = r when s > 199 and s < 300 <-
           post(client, "/api/images", body) do
      BotState.set_job_progress(image_filename, %{
        prog
        | status: "Complete",
          percent: 100
      })

      r
    else
      {:ok, %{status: s, body: body}} when s > 399 ->
        FarmbotOS.Logger.error(
          1,
          "Failed to upload image (HTTP: #{s}): #{inspect(body)}"
        )

        BotState.set_job_progress(image_filename, %{
          prog
          | percent: -1,
            status: "Error"
        })

        {:error, body}

      er ->
        FarmbotOS.Logger.error(1, "Failed to upload image: #{inspect(er)}")

        BotState.set_job_progress(image_filename, %{
          prog
          | percent: -1,
            status: "Error"
        })

        er
    end
  end

  defp put_progress(prog, size, max) do
    fraction = size / max
    completed = trunc(fraction * @progress_steps)
    percent = trunc(fraction * 100)
    unfilled = @progress_steps - completed

    IO.write(
      :stderr,
      "\r|#{String.duplicate("=", completed)}#{String.duplicate(" ", unfilled)}| #{percent}% (#{bytes_to_mb(size)} / #{bytes_to_mb(max)}) MB"
    )

    status = if percent == 100, do: "Complete", else: "Working"

    %Percent{
      prog
      | status: status,
        percent: percent
    }
  end

  defp bytes_to_mb(bytes) do
    trunc(bytes / 1024 / 1024)
  end

  defp get_body_error(path, status, error) when is_binary(error) do
    msg = """
    HTTP Error getting: #{path}
    Status Code = #{status}

    #{error}
    """

    {:error, msg}
  end

  defp adapter() do
    {Tesla.Adapter.Hackney,
     ssl: [verify: :verify_peer, cacertfile: :certifi.cacertfile()]}
  end
end
