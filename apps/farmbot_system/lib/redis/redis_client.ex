defmodule Redis.Client do
  use GenServer
  require Logger
  # 15 minutes
  @save_time 900000

  @doc """
    Start the redis server.
  """
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init([]) do
    exe = System.find_executable("redis-cli")
    port = Port.open({:spawn_executable, exe},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout,
       args: []])
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
    Farmbot.System.FS.transaction fn() -> Redis.Client.send("SAVE") end
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
  @spec send(binary) :: binary
  def send(str), do: GenServer.call(__MODULE__, {:send, str})

  @doc """
    Input a value by a given key.
  """
  @spec input_value(String.t, any) :: [String.t]
  def input_value(key, value) when is_map(value) do
    input_map(%{key => value})
  end

  def input_value(key, value) when is_list(value) do
    input_list(key, value)
  end

  def input_value(key, value) when is_tuple(value) do
    input_value(key, Tuple.to_list(value))
  end

  def input_value(key, value), do: send "SET #{key} #{value}"

  @doc """
    Input a list to redis under key
  """
  defp input_list(key, list) do
    send("DEL #{key}")
    rlist = Enum.reduce(list, "", fn(item, acc) ->
      if is_binary(item) || is_integer(item),
        do: acc <> " " <> "#{item}", else: acc
    end)
    send("RPUSH #{key} #{rlist}")
  end

  @spec input_map(map | struct, String.t | nil) :: [String.t]
  defp input_map(map, bloop \\ nil)
  defp input_map(%{__struct__: _} = map, bloop),
    do: map |> Map.from_struct |> input_map(bloop)

  defp input_map(map, bloop) when is_map(map) do
    Enum.map(map, fn({key, value}) ->
      cond do
        is_map(value) ->
          if bloop do
            input_map(value, "#{bloop}.#{key}")
          else
            input_map(value, key)
          end

        is_list(value) ->
          if bloop do
            input_list("#{bloop}.#{key}", value)
          else
            input_list(key, value)
          end

        true ->
          if bloop do
            input_value("#{bloop}.#{key}", value)
          else
            input_value(key, value)
          end
      end
    end)
    |> List.flatten
  end
end
