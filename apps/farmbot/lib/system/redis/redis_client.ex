defmodule Redis.Client do
  @moduledoc """
    Command line redis client
  """
  use GenServer
  require Logger
  # 15 minutes
  @save_time 900_000
  @port Application.get_env(:farmbot, :redis_port)

  @doc """
    Start the redis server.
  """
  def start_link, do: GenServer.start_link(__MODULE__, [])

  def init([]) do
    exe = System.find_executable("redis-cli")
    port = Port.open({:spawn_executable, exe},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout,
       args: ["-p", "#{@port}"]])
     Process.send_after(self(), :save, @save_time)
     {:ok, %{cli: port, queue: :queue.new(), blah: nil}}
  end

  def handle_info({_cli, {:data, info}}, state) do
    info = String.trim(info)
    if state.blah do GenServer.reply(state.blah, info) end
    {:noreply, %{state | blah: nil}}
  end

  def handle_info(:save, state) do
    # Since this is a function that doesnt get executed right now, we can
    # have this GenServer call itself tehe
    me = self()
    Farmbot.System.FS.transaction fn() -> Redis.Client.send_redis(me, "SAVE") end
    # send ourselves a message in x seconds
    Process.send_after(self(), :save, @save_time)
    {:noreply, state}
  end

  def handle_call({:send, str}, from, state) do
    Port.command(state.cli, str <> "\n")
    {:noreply, %{state | blah: from}}
  end

  @doc """
    Sends a command to redis client. This is blocking.
  """
  @spec send_redis(pid, binary) :: binary
  def send_redis(pid, str), do: GenServer.call(pid, {:send, str})

  @doc """
    Input a value by a given key.
  """
  @spec input_value(pid, String.t, any) :: [String.t]
  def input_value(redis, key, value) when is_map(value) do
    input_map(redis, %{key => value})
  end

  def input_value(redis, key, value) when is_list(value) do
    input_list(redis, key, value)
  end

  def input_value(redis, key, value) when is_tuple(value) do
    input_value(redis, key, Tuple.to_list(value))
  end

  def input_value(redis, key, value), do: send_redis redis, "SET #{key} #{value}"

  defp input_list(redis, key, list) do
    send_redis(redis, "DEL #{key}")
    rlist = Enum.reduce(list, "", fn(item, acc) ->
      if is_binary(item) || is_integer(item),
        do: acc <> " " <> "#{item}", else: acc
    end)
    send_redis(redis, "RPUSH #{key} #{rlist}")
  end

  @spec input_map(pid, map | struct, String.t | nil) :: [String.t]
  defp input_map(redis, map, bloop \\ nil)
  defp input_map(redis, %{__struct__: _} = map, bloop),
    do: input_map(redis, map |> Map.from_struct, bloop)

  @lint false
  defp input_map(redis, map, bloop) when is_map(map) do
    Enum.map(map, fn({key, value}) ->
      cond do
        is_map(value) ->
          if bloop do
            input_map(redis, value, "#{bloop}.#{key}")
          else
            input_map(redis, value, key)
          end

        is_list(value) ->
          if bloop do
            input_list(redis, "#{bloop}.#{key}", value)
          else
            input_list(redis, key, value)
          end

        true ->
          if bloop do
            input_value(redis, "#{bloop}.#{key}", value)
          else
            input_value(redis, key, value)
          end
      end
    end)
    |> List.flatten
  end
end
