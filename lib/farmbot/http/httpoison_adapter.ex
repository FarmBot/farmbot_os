defmodule Farmbot.HTTP.HTTPoisonAdapter do
  @moduledoc """
  Farmbot HTTP adapter for accessing the world and farmbot web api easily.
  """

  # credo:disable-for-this-file Credo.Check.Refactor.FunctionArity

  use GenServer
  alias HTTPoison
  alias HTTPoison.{AsyncResponse, AsyncStatus, AsyncHeaders, AsyncChunk, AsyncEnd}
  alias Farmbot.HTTP.{Response, Helpers}
  import Helpers

  @behaviour Farmbot.HTTP.Adapter

  @version Farmbot.Project.version()
  @target Farmbot.Project.target()
  @redirect_status_codes [301, 302, 303, 307, 308]

  def request(http, method, url, body, headers, opts) do
    GenServer.call(http, {:req, method, url, body, headers, opts}, :infinity)
  end

  def download_file(http, url, path, progress_callback, payload, headers, stream_fun) do
    case request(
           http,
           :get,
           url,
           payload,
           headers,
           file: path,
           stream_fun: stream_fun,
           progress_callback: progress_callback
         ) do
      {:ok, %Response{status_code: code}} when is_2xx(code) -> {:ok, path}
      {:ok, %Response{} = resp} -> {:error, resp}
      {:error, reason} -> {:error, reason}
    end
  end

  def upload_file(http, path, meta) do
    http
    |> request(:get, "/api/storage_auth", "", [], [])
    |> do_multipart_request(http, meta, path)
  end

  defp do_multipart_request({:ok, %Response{status_code: code, body: bin_body}}, http, meta, path)
       when is_2xx(code) do
    with {:ok, body} <- Poison.decode(bin_body),
         {:ok, file} <- File.read(path) do
      url = "https:" <> body["url"]
      form_data = body["form_data"]
      attachment_url = url <> form_data["key"]

      mp =
        Enum.map(form_data, fn {key, val} ->
          if key == "file", do: {"file", file}, else: {key, val}
        end)

      http
      |> request(:post, url, {:multipart, mp}, [], [])
      |> finish_upload(http, attachment_url, meta)
    end
  end

  defp do_multipart_request({:ok, %Response{} = response}, _http, _meta, _path),
    do: {:error, response}

  defp do_multipart_request({:error, reason}, _http, _meta, _path), do: {:error, reason}

  defp finish_upload({:ok, %Response{status_code: code}}, http, atch_url, meta) when is_2xx(code) do
    with {:ok, body} <- Poison.encode(%{"attachment_url" => atch_url, "meta" => meta}) do
      case request(http, :post, "/api/images", body, [], []) do
        {:ok, %Response{status_code: code} = resp} when is_2xx(code) ->
          {:ok, resp}

        {:ok, %Response{} = response} ->
          {:error, response}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp finish_upload({:ok, %Response{} = resp}, _http, _url, _meta), do: {:error, resp}
  defp finish_upload({:error, reason}, _http, _url, _meta), do: {:error, reason}

  # GenServer

  defmodule State do
    @moduledoc false
    defstruct [:requests]
  end

  defmodule Buffer do
    @moduledoc false
    defstruct [
      :data,
      :headers,
      :status_code,
      :request,
      :from,
      :id,
      :file,
      :timeout,
      :progress_callback,
      :stream_fun,
      :file_size
    ]
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init([]) do
    state = %State{requests: %{}}
    {:ok, state}
  end

  def handle_call({:req, method, url, body, headers, opts}, from, state) do
    {file, opts} = maybe_open_file(opts)
    opts = fb_opts(opts)
    headers = fb_headers(headers)
    # Pattern match the url.
    case url do
      "/api" <> _ -> do_api_request({method, url, body, headers, opts, from}, state)
      _ -> do_normal_request({method, url, body, headers, opts, from}, file, state)
    end
  end

  def handle_info({:timeout, ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer ->
        GenServer.reply(buffer.from, {:error, :timeout})
        {:noreply, %{state | requests: Map.delete(state.requests, ref)}}

      nil ->
        {:noreply, state}
    end
  end

  def handle_info(%AsyncStatus{code: code, id: ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer ->
        HTTPoison.stream_next(%AsyncResponse{id: ref})
        {:noreply, %{state | requests: %{state.requests | ref => %{buffer | status_code: code}}}}

      nil ->
        {:noreply, state}
    end
  end

  def handle_info(%AsyncHeaders{headers: headers, id: ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer ->
        file_size =
          Enum.find_value(headers, fn {header, val} ->
            # credo:disable-for-next-line
            case header do
              "Content-Length" -> val
              "content_length" -> val
              _header -> nil
            end
          end)

        HTTPoison.stream_next(%AsyncResponse{id: ref})
        new_ref = %{buffer | headers: headers, file_size: file_size}
        new_requests = %{state.requests | ref => new_ref}
        new_state = %{state | requests: new_requests}

        {:noreply, new_state}
      nil ->
        {:noreply, state}
    end
  end

  def handle_info(%AsyncChunk{chunk: chunk, id: ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer ->
        if buffer.timeout, do: Process.cancel_timer(buffer.timeout)
        timeout = Process.send_after(self(), {:timeout, ref}, 30_000)
        maybe_log_progress(buffer)

        case buffer.stream_fun do
          nil ->
            maybe_stream_to_file(buffer.file, buffer.status_code, chunk)

          fun when is_function(fun) ->
            fun.(buffer.status_code, chunk)
        end

        HTTPoison.stream_next(%AsyncResponse{id: ref})

        new_ref = %{buffer | data: buffer.data <> chunk, timeout: timeout}
        new_requests = %{state.requests | ref => new_ref}
        new_state = %{state | requests: new_requests}
        {:noreply, new_state}
      nil ->
        {:noreply, state}
    end
  end

  def handle_info(%AsyncEnd{id: ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer ->
        finish_request(buffer, state)

      nil ->
        {:noreply, state}
    end
  end

  def terminate({:error, reason}, state), do: terminate(reason, state)

  def terminate(reason, state) do
    for {_ref, buffer} <- state.requests do
      maybe_close_file(buffer.file)
      GenServer.reply(buffer.from, {:error, reason})
    end
  end

  defp maybe_open_file(opts) do
    {file, opts} = Keyword.pop(opts, :file)

    case file do
      filename when is_binary(filename) ->
        if Keyword.get(opts, :stream_fun) do
          # If there is a stream function, don't open the file.
          {nil, opts}
        else
          # If there is, delete the old file,
          File.rm(file)
          # Make sure it exists and is empty
          :ok = File.touch(filename)
          # Open the file
          {:ok, fd} = :file.open(filename, [:write, :raw])
          # Set opts.
          {fd, Keyword.merge(opts, stream_to: self(), async: :once)}
        end

      _ ->
        {nil, opts}
    end
  end

  defp maybe_stream_to_file(nil, _, _data), do: :ok
  defp maybe_stream_to_file(_, code, _data) when code in @redirect_status_codes, do: :ok

  defp maybe_stream_to_file(fd, _code, data) when is_binary(data) do
    :ok = :file.write(fd, data)
  end

  defp maybe_close_file(nil), do: :ok
  defp maybe_close_file(fd), do: :file.close(fd)

  defp maybe_log_progress(%Buffer{file: file, progress_callback: pcb})
       when is_nil(file) or is_nil(pcb) do
    :ok
  end

  defp maybe_log_progress(%Buffer{file: _file, file_size: fs} = buffer) do
    downloaded_bytes = byte_size(buffer.data)

    case fs do
      numstr when is_binary(numstr) ->
        total_bytes = numstr |> String.to_integer()
        buffer.progress_callback.(downloaded_bytes, total_bytes)

      other when other in [:complete] or is_nil(other) ->
        buffer.progress_callback.(downloaded_bytes, other)
    end
  end

  defp do_api_request({method, url, body, headers, opts, from}, state) do
    alias Farmbot.System.ConfigStorage
    token = ConfigStorage.get_config_value(:string, "authorization", "token")
    url = ConfigStorage.get_config_value(:string, "authorization", "server") <> url

    headers =
      headers
      |> add_header({"Authorization", "Bearer " <> token})
      |> add_header({"Content-Type", "application/json"})

    opts = opts |> Keyword.put(:timeout, :infinity)
    do_normal_request({method, url, body, headers, opts, from}, nil, state)
  end

  defp do_normal_request({method, url, body, headers, opts, from}, file, state) do
    case HTTPoison.request(method, url, body, headers, opts) do
      {:ok, %HTTPoison.Response{status_code: code, headers: resp_headers}}
      when code in @redirect_status_codes ->
        redir =
          Enum.find_value(resp_headers, fn {header, val} ->
            # credo:disable-for-next-line
            if header == "Location", do: val, else: false
          end)

        if redir do
          do_normal_request({method, redir, body, headers, opts, from}, file, state)
        else
          GenServer.reply(from, {:error, :no_server_for_redirect})
          {:noreply, state}
        end

      {:ok, %HTTPoison.Response{body: body, headers: headers, status_code: code}} ->
        GenServer.reply(from, {:ok, %Response{body: body, headers: headers, status_code: code}})
        {:noreply, state}

      {:ok, %AsyncResponse{id: ref}} ->
        timeout = Process.send_after(self(), {:timeout, ref}, 30_000)

        req = %Buffer{
          id: ref,
          from: from,
          timeout: timeout,
          file: file,
          data: "",
          headers: nil,
          status_code: nil,
          stream_fun: Keyword.get(opts, :stream_fun, nil),
          progress_callback: Keyword.fetch!(opts, :progress_callback),
          request: {method, url, body, headers, opts}
        }

        {:noreply, %{state | requests: Map.put(state.requests, ref, req)}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        GenServer.reply(from, {:error, reason})
        {:noreply, state}

      {:error, reason} ->
        GenServer.reply(from, {:error, reason})
        {:noreply, state}
    end
  end

  defp do_redirect_request(%Buffer{} = buffer, redir, state) do
    {method, _url, body, headers, opts} = buffer.request

    case HTTPoison.request(method, redir, body, headers, opts) do
      {:ok, %AsyncResponse{id: ref}} ->
        req = %Buffer{
          buffer
          | id: ref,
            from: buffer.from,
            file: buffer.file,
            data: "",
            headers: nil,
            status_code: nil,
            request: {method, redir, body, headers, opts}
        }

        state = %{state | requests: Map.delete(state.requests, buffer.id)}
        state = %{state | requests: Map.put(state.requests, ref, req)}
        {:noreply, state}

      {:error, %HTTPoison.Error{reason: reason}} ->
        GenServer.reply(buffer.from, {:error, reason})
        {:noreply, state}

      {:error, reason} ->
        GenServer.reply(buffer.from, {:error, reason})
        {:noreply, state}
    end
  end

  defp finish_request(%Buffer{status_code: status_code} = buffer, state)
       when status_code in @redirect_status_codes do
    redir =
      Enum.find_value(buffer.headers, fn {header, val} ->
        case header do
          "Location" -> val
          "location" -> val
          _ -> false
        end
      end)

    if redir do
      do_redirect_request(buffer, redir, state)
    else
      GenServer.reply(buffer.from, {:error, :no_server_for_redirect})
      {:noreply, state}
    end
  end

  defp finish_request(%Buffer{} = buffer, state) do
    response = %Response{
      status_code: buffer.status_code,
      body: buffer.data,
      headers: buffer.headers
    }

    if buffer.timeout, do: Process.cancel_timer(buffer.timeout)
    maybe_close_file(buffer.file)

    case buffer.file_size do
      nil -> maybe_log_progress(%{buffer | file_size: :complete})
      _num -> maybe_log_progress(%{buffer | file_size: "#{byte_size(buffer.data)}"})
    end

    GenServer.reply(buffer.from, {:ok, response})
    {:noreply, %{state | requests: Map.delete(state.requests, buffer.id)}}
  end

  defp fb_headers(headers) do
    headers |> add_header({"User-Agent", "FarmbotOS/#{@version} (#{@target}) #{@target} ()"})
  end

  defp add_header(headers, new), do: [new | headers]

  defp fb_opts(opts) do
    Keyword.merge(
      opts,
      ssl: [{:versions, [:"tlsv1.2"]}],
      hackney: [:insecure, pool: :farmbot_http_pool],
      recv_timeout: :infinity,
      timeout: :infinity
    )
  end
end
