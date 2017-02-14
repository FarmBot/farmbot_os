defmodule Redis.Client do
  use GenServer
  require Logger

  @doc """
    Start the redis server.
  """
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

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
     {:ok, %{cli: port, queue: :queue.new(), blah: nil}}
  end

  def handle_info({cli, {:data, info}}, state) do
    info = String.trim(info)
    if state.blah do GenServer.reply(state.blah, info) end
    {:noreply, %{state | blah: nil}}
  end

  def handle_call({:send, str}, from, state) do
    Port.command(state.cli, str <> "\n")
    {:noreply, %{state | blah: from}}
  end

  def send(str) do
    GenServer.call(__MODULE__, {:send, str})
  end

  @doc """
    Input a value by a given key.
  """
  @spec input_value(String.t, any) :: [String.t]
  def input_value(key, value) when is_map(value) do
    input_map(%{key => value})
  end

  def input_value(key, value) when is_list(value) do
    input_list(key, list)
  end

  def input_value(key, value) when is_tuple(value) do
    input_value(key, Tuple.to_list(value))
  end

  def input_value(key, value) do
    send "SET #{key} #{value}"
  end

  @doc """
    Input a list to redis under key
  """
  def input_list(key, list) do
    "OK"
  end

  @doc """
    Input a map into redis
  """
  @spec input_map(map | struct, String.t | nil) :: [String.t]
  def input_map(map, bloop \\ nil)
  def input_map(%{__struct__: _} = map, bloop), do: map |> Map.from_struct |> input_map(bloop)
  def input_map(map, bloop) when is_map(map) do
    Enum.map(map, fn({key, value}) ->
      cond do
        is_map(value) ->
          if bloop do
            input_map(value, "#{bloop}.#{key}")
          else
            input_map(value, key)
          end

        is_list(value) -> input_list(key, value)

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
