defmodule Logger.Backends.FarmbotLogger do
  @moduledoc """
    Logger backend for logging to the frontend and dumping to the API.
    Takes messages that were logged useing Logger, if they can be
    jsonified, adds them too a buffer, when that buffer hits a certain
    size, it tries to dump the messages onto the API.
  """
  alias Farmbot.{Context, HTTP}
  use GenEvent
  require Logger
  use Farmbot.DebugLog
  @save_path Application.get_env(:farmbot, :path) <> "/logs.txt"

  # ten megs. i promise
  @max_file_size 1.0e+7
  @filtered "[FILTERED]"

  @log_amnt 10

  @typedoc """
    The state of the logger
  """
  @type state :: %{logs: [log_message], posting: boolean, context: nil | Context.t}

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
     | :debug

  @typedoc """
    Elixir Logger level type
  """
  @type logger_level
    :: :info
     | :warn
     | :error
     | :debug

  @typedoc """
    One day this will me more
  """
  @type channel :: :toast | :email

  @type log_message
  :: %{message: String.t,
       channels: [channel],
       created_at: integer,
       meta: %{type: rpc_log_type}}

  def init(_) do
    # ctx = Farmbot.Context.new()
    debug_log "Starting Farmbot Logger"
    {:ok, %{logs: [], posting: false, context: nil}}
  end

  # The example said ignore messages for other nodes, so im ignoring messages
  # for other nodes.
  def handle_event({_, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  # The logger event.
  def handle_event({_level, _, {Logger, _, _, _}}, %{context: nil} = state) do
    debug_log "Ignoreing message because no context"
    {:ok, state}
  end

  def handle_event({level, _, {Logger, message, timestamp, metadata}}, state) do
    # if there is type key in the meta we need that to have priority
    type = Keyword.get(metadata, :type, level)
    channels = Keyword.get(metadata, :channels, [])
    created_at = parse_created_at(timestamp)
    san_m = sanitize(message, metadata, state)
    log = build_log(san_m, created_at, type, channels)
    :ok = GenServer.cast(state.context.transport, {:log, log})
    logs = [log | state.logs]
    if (!state.posting) and (Enum.count(logs) >= @log_amnt) do
      # If not already posting, and more than 50 messages
      spawn fn ->
        # debug_log "going to try to post"
        filterd_logs = Enum.filter(logs, fn(log) ->
          log.message != @filtered
        end)
        do_post(state.context, filterd_logs)
      end
      {:ok, %{state | logs: logs, posting: true}}
    else
      # debug_log "not posting and logs less than 50"
      {:ok, %{state | logs: logs}}
    end
  end

  def handle_event(:flush, state), do: {:ok, %{state | logs: [], posting: false}}

  def handle_call(:post_success, state) do
    debug_log "Logs uploaded!"
    write_file(Enum.reverse(state.logs))
    {:ok, :ok, %{state | posting: false, logs: []}}
  end

  def handle_call(:post_fail, state) do
    debug_log "Logs failed to upload!"
    {:ok, :ok, %{state | posting: false}}
  end

  def handle_call(:messages, state) do
    {:ok, Enum.reverse(state.logs), state}
  end

  def handle_call({:context, %Context{} = ctx}, state) do
    {:ok, :ok, %{state | context: ctx}}
  end

  def handle_call(:get_state, state), do: {:ok, state, state}

  @spec do_post(Context.t, [log_message]) :: no_return
  defp do_post(%Context{} = ctx, logs) do
    try do
      debug_log "doing post"
      {:ok, %{status_code: 200}} = HTTP.post(ctx, "/api/logs", Poison.encode!(logs))
      :ok = GenEvent.call(Elixir.Logger, __MODULE__, :post_success)
    rescue
      e ->
        debug_log "post failed: #{inspect e}"
        :ok = GenEvent.call(Elixir.Logger, __MODULE__, :post_fail)
    end
  end

  @spec write_file([log_message]) :: no_return
  defp write_file(logs) do
    debug_log("Writing log file!")
    old = read_file()
    new_file = Enum.reduce(logs, old, fn(log, acc) ->
      if log.message != @filtered do
        acc <> log.message <> "\r\n"
      else
        acc
      end
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

  @spec sanitize(binary, [any], state) :: String.t
  defp sanitize(message, meta, state) do
    module = Keyword.get(meta, :module)
    unless meta[:nopub] do
      message
      |> filter_module(module)
      |> filter_text(state)
    end
  end

  @modules [
    :"Elixir.Nerves.InterimWiFi",
    :"Elixir.Nerves.NetworkInterface",
    :"Elixir.Nerves.InterimWiFi.WiFiManager.EventHandler",
    :"Elixir.Nerves.InterimWiFi.WiFiManager",
    :"Elixir.Nerves.InterimWiFi.DHCPManager",
    :"Elixir.Nerves.InterimWiFi.Udhcpc",
    :"Elixir.Nerves.NetworkInterface.Worker",
    :"Elixir.Nerves.InterimWiFi.DHCPManager.EventHandler",
    :"Elixir.Nerves.WpaSupplicant",
  ]

  for module <- @modules, do: defp filter_module(_, unquote(module)), do: @filtered
  defp filter_module(message, _module), do: message

  defp filter_text(">>" <> m, state) do
    device = try do
      Farmbot.Database.Selectors.get_device(state.context)
    rescue
      _e in Farmbot.Database.Selectors.Error -> %{name: "Farmbot"}
    end

    filter_text(device.name <> m, state)
  end

  defp filter_text(m, _state) when is_binary(m) do
    try do
      Poison.encode!(m)
      m
    rescue
      _ -> @filtered
    end
  end
  defp filter_text(_message, _state), do: @filtered

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
    |> DateTime.to_unix#(:milliseconds)
  end

  @spec build_log(String.t, number, rpc_log_type, [channel]) :: log_message
  defp build_log(message, created_at, type, channels) do
    %{message: message,
      created_at: created_at,
      channels: channels,
      meta: %{type: type}}
  end
end
