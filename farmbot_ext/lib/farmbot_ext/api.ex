defmodule FarmbotExt.API do
  alias FarmbotExt.{API, JWT}

  alias FarmbotCore.JSON

  alias FarmbotCore.Asset.{
    FbosConfig,
    FirmwareConfig,
    StorageAuth
  }

  alias FarmbotCore.{BotState, BotState.JobProgress.Percent, Project}

  require FarmbotCore.Logger
  import FarmbotCore.Config, only: [get_config_value: 3]

  use Tesla
  alias Tesla.Multipart

  @version Project.version()
  @target Project.target()

  # adapter(Tesla.Adapter.Hackney)
  plug(Tesla.Middleware.JSON, decode: &JSON.decode/1, encode: &JSON.encode/1)
  plug(Tesla.Middleware.FollowRedirects)
  # plug(Tesla.Middleware.Logger)

  def client do
    binary_token = get_config_value(:string, "authorization", "token")
    server = get_config_value(:string, "authorization", "server")
    {:ok, _tkn} = JWT.decode(binary_token)

    uri = URI.parse(server)
    url = (uri.scheme || "https") <> "://" <> uri.host <> ":" <> to_string(uri.port)
    user_agent = "FarmbotOS/#{@version} (#{@target}) #{@target} ()"

    Tesla.client([
      {Tesla.Middleware.BaseUrl, url},
      {Tesla.Middleware.Headers,
       [
         {"content-type", "application/json"},
         {"authorization", "Bearer: " <> binary_token},
         {"user-agent", user_agent}
       ]}
    ])
  end

  def storage_client(%StorageAuth{url: url}) do
    server = get_config_value(:string, "authorization", "server")
    uri = URI.parse(server)
    user_agent = "FarmbotOS/#{@version} (#{@target}) #{@target} ()"

    Tesla.client([
      {Tesla.Middleware.BaseUrl, "#{uri.scheme}:#{url}"},
      {Tesla.Middleware.Headers,
       [
         {"user-agent", user_agent}
       ]},
      {Tesla.Middleware.FormUrlencoded, []}
    ])
  end

  @file_chunk 4096
  @progress_steps 50

  def upload_image(image_filename, meta \\ %{}) do
    {:ok, changeset} = API.get_changeset(StorageAuth)
    storage_auth = %StorageAuth{form_data: form_data} = Ecto.Changeset.apply_changes(changeset)

    content_length = :filelib.file_size(image_filename)
    {:ok, pid} = Agent.start_link(fn -> 0 end)

    prog = %Percent{
      status: "working",
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

    opts =
      if String.contains?(storage_auth.url, "direct_upload") do
        []
      else
        [filename: image_filename, headers: [{"Content-Type", "image/jpeg"}]]
      end

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
      |> API.storage_client()
      |> API.request(
        method: String.to_existing_atom(String.downcase(storage_auth.verb)),
        body: mp
      )

    with {:ok, %{url: url, status: s}} when s > 199 and s < 300 <- storage_resp,
         attachment_url <- Path.join(url, form_data.key),
         client <- API.client(),
         body <- %{attachment_url: attachment_url, meta: meta},
         {:ok, %{status: s}} = r when s > 199 and s < 300 <- API.post(client, "/api/images", body) do
      BotState.set_job_progress(image_filename, %{prog | status: "complete", percent: 100})
      r
    else
      {:ok, %{status: s, body: body}} when s > 399 ->
        FarmbotCore.Logger.error(1, "Failed to upload image (HTTP: #{s}): #{inspect(body)}")
        BotState.set_job_progress(image_filename, %{prog | percent: -1, status: "error"})
        {:error, body}

      er ->
        FarmbotCore.Logger.error(1, "Failed to upload image: #{inspect(er)}")
        BotState.set_job_progress(image_filename, %{prog | percent: -1, status: "error"})
        er
    end
  end

  def put_progress(prog, size, max) do
    fraction = size / max
    completed = trunc(fraction * @progress_steps)
    percent = trunc(fraction * 100)
    unfilled = @progress_steps - completed

    IO.write(
      :stderr,
      "\r|#{String.duplicate("=", completed)}#{String.duplicate(" ", unfilled)}| #{percent}% (#{
        bytes_to_mb(size)
      } / #{bytes_to_mb(max)}) MB"
    )

    status = if percent == 100, do: "complete", else: "working"

    %Percent{
      prog
      | status: status,
        percent: percent
    }
  end

  defp bytes_to_mb(bytes) do
    trunc(bytes / 1024 / 1024)
  end

  @doc "helper for `GET`ing a path."
  def get_body!(path) do
    case API.get(API.client(), path) do
      {:ok, %{body: body, status: 200}} ->
        {:ok, body}

      {:ok, %{body: error, status: status}} when is_binary(error) ->
        get_body_error(path, status, error)

      {:ok, %{body: %{"error" => error}, status: status}} when is_binary(error) ->
        get_body_error(path, status, error)

      {:ok, %{body: error, status: status}} when is_binary(error) ->
        get_body_error(path, status, inspect(error))

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_body_error(path, status, error) when is_binary(error) do
    msg = """
    HTTP Error getting: #{path}
    Status Code = #{status}

    #{error}
    """

    {:error, msg}
  end

  @callback get_changeset(module) :: {:ok, %Ecto.Changeset{}} | {:error, term()}
  @callback get_changeset(data :: module | map(), Path.t()) ::
              {:ok, %Ecto.Changeset{}} | {:error, term()}

  @doc "helper for `GET`ing api resources."
  def get_changeset(module) when is_atom(module) do
    get_changeset(struct(module))
  end

  def get_changeset(%module{} = data) do
    get_body!(module.path() <> ".json")
    |> case do
      {:ok, %{} = single} ->
        {:ok, module.changeset(data, single)}

      {:ok, many} when is_list(many) ->
        {:ok, Enum.map(many, &module.changeset(data, &1))}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "helper for `GET`ing api resources."
  def get_changeset(asset, path)

  # Hacks for dealing with these resources not having #show
  def get_changeset(FbosConfig, _),
    do: get_changeset(FbosConfig)

  def get_changeset(FirmwareConfig, _),
    do: get_changeset(FirmwareConfig)

  def get_changeset(%FbosConfig{} = data, _),
    do: get_changeset(data)

  def get_changeset(%FirmwareConfig{} = data, _),
    do: get_changeset(data)

  def get_changeset(module, path) when is_atom(module) do
    get_changeset(struct(module), path)
  end

  def get_changeset(%module{} = data, path) do
    get_body!(Path.join(module.path(), to_string(path) <> ".json"))
    |> case do
      {:ok, %{} = single} ->
        {:ok, module.changeset(data, single)}

      {:ok, many} when is_list(many) ->
        {:ok, Enum.map(many, &module.changeset(data, &1))}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
