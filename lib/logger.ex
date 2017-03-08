defmodule Farmbot.Logger do
  @moduledoc """
    Logger backend for logging to the frontend and dumping to the API.
    Takes messages that were logged useing Logger, if they can be
    jsonified, adds them too a buffer, when that buffer hits a certain
    size, it tries to dump the messages onto the API.
  """
  alias Farmbot.Sync
  alias Farmbot.HTTP
  use GenEvent
  require Logger
  @save_path Application.get_env(:farmbot, :path) <> "/logs.txt"

  # ten megs. i promise
  @max_file_size 1.0e+7
  # @max_file_size 50000

  @typedoc """
    The state of the logger
  """
  @type state :: %{logs: [log_message], posting: boolean}

  @typedoc """
    Type of message for ticker
  """
  @type rpc_log_type
    :: :success
     | :busy
     | :warn
     | :error
     | :info
     | :fun

  @typedoc """
    Elixir Logger level type
  """
  @type logger_level
    :: :info
     | :debug
     | :warn
     | :error

  @typedoc """
    One day this will me more
  """
  @type channels :: :toast

  @type log_message
  :: %{message: String.t,
       channels: channels,
       created_at: integer,
       meta: %{type: rpc_log_type}}

  def init(_), do: {:ok, %{logs: [], posting: false}}

  # The example said ignore messages for other nodes, so im ignoring messages
  # for other nodes.
  def handle_event({_, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  # The logger event.
  def handle_event({level, _, {Logger, message, timestamp, metadata}}, state) do
    # if there is type key in the meta we need that to have priority
    type = Keyword.get(metadata, :type, level)
    channels = Keyword.get(metadata, :channels, [])
    created_at = parse_created_at(timestamp)
    san_m = sanitize(message, metadata)
    log = build_log(san_m, created_at, type, channels)
    :ok = GenServer.cast(Farmbot.Transport, {:log, log})
    logs = [log | state.logs]
    if !state.posting and Enum.count(logs) >= 50 do
      # If not already posting, and more than 50 messages
      spawn fn -> do_post(logs) end
      {:ok, %{state | logs: logs, posting: true}}
    else
      {:ok, %{state | logs: logs}}
    end
  end

  def handle_event(:flush, _state), do: {:ok, %{logs: [], posting: false}}

  def handle_call(:post_success, state) do
    write_file(Enum.reverse(state.logs))
    {:ok, :ok, %{state | posting: false, logs: []}}
  end

  def handle_call(:post_fail, state) do
    {:ok, :ok, %{state | posting: false}}
  end

  @spec do_post([log_message]) :: no_return
  defp do_post(logs) do
    try do
      case HTTP.post("/api/logs", Poison.encode!(logs)) do
        {:ok, _} ->
          IO.puts "success"
          GenEvent.call(Elixir.Logger, __MODULE__, :post_success)
        e ->
          IO.puts "FAILED TO POST LOGS: #{inspect e}"
          raise "POST FAIL"
      end
    rescue
      _ -> GenEvent.call(Elixir.Logger, __MODULE__, :post_fail)
    end
  end

  @spec write_file([log_message]) :: no_return
  defp write_file(logs) do
    old = read_file()
    new_file = Enum.reduce(logs, old, fn(log, acc) ->
      acc <> log.message <> "\r\n"
    end)

    bin = fifo(new_file)

    Farmbot.System.FS.transaction fn ->
      File.write(@save_path, bin <> "\r\n")
    end
  end

  # reads the current file.
  # if the file isnt found, returns an empty string
  @spec read_file :: binary
  defp read_file do
    case File.read(@save_path) do
      {:ok, bin} -> bin
      _ -> ""
    end
  end

  # if the file is to big, fifo it
  # trim lines off the file until it is smaller than @max_file_size
  @spec fifo(binary) :: binary
  defp fifo(new_file) when byte_size(new_file) > @max_file_size do
    # IO.puts "file size: #{byte_size(new_file)}"
    [_ | rest] = String.split(new_file, "\r\n")
    fifo(Enum.join(rest, "\r\n"))
  end

  defp fifo(new_file), do: new_file

  # if this backend crashes just pop it out of the logger backends.
  # if we don't do this it bacomes a huge mess because of Logger
  # trying to restart this module
  # then this module dying again
  # then printing a HUGE supervisor report
  # then Logger trying to add it again  etc
  def terminate(_,_), do: spawn fn -> Logger.remove_backend(__MODULE__) end

  @spec sanitize(binary, [any]) :: String.t
  defp sanitize(message, meta) do
    module = Keyword.get(meta, :module)
    unless meta[:nopub] do
      message
      |> filter_module(module)
      |> filter_text()
    end
  end

  @filtered "[FILTERED]"
  @modules [
    :"Elixir.Nerves.InterimWiFi",
    :"Elixir.Nerves.NetworkInterface",
    :"Elixir.Nerves.InterimWiFi.WiFiManager.EventHandler",
    :"Elixir.Nerves.InterimWiFi.DHCPManager",
    :"Elixir.Nerves.NetworkInterface.Worker",
    :"Elixir.Nerves.InterimWiFi.DHCPManager.EventHandler"
  ]

  for module <- @modules, do: defp filter_module(_, unquote(module)), do: @filtered
  defp filter_module(message, _module), do: message

  defp filter_text(">>" <> m), do: filter_text("#{Sync.device_name()}" <> m)
  defp filter_text(m) when is_binary(m) do
    try do
      Poison.encode!(m)
    rescue
      _ -> @filtered
    end
  end
  defp filter_text(_message), do: @filtered

  # Couuld probably do this inline but wheres the fun in that. its a functional
  # language isn't it?
  # Takes Loggers time stamp and converts it into a unix timestamp.
  defp parse_created_at({{year, month, day}, {hour, minute, second, _mil}}) do
    %DateTime{year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      microsecond: {0,0},
      std_offset: 0,
      time_zone: "Etc/UTC",
      utc_offset: 0,
      zone_abbr: "UTC"}
    |> DateTime.to_iso8601
  end

  @spec build_log(String.t, number, rpc_log_type, [channels]) :: log_message
  defp build_log(message, created_at, type, channels) do
    %{message: message,
      created_at: created_at,
      channels: channels,
      meta: %{type: type}}
  end
end
