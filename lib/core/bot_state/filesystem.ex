defmodule FarmbotOS.BotState.FileSystem do
  @moduledoc """
  Serializes Farmbot's state into a location on a filesystem.
  """

  require Logger
  use GenServer
  alias FarmbotOS.BotState

  @root_dir Application.compile_env(:farmbot, __MODULE__)[:root_dir]
  @sleep_time 8_000

  @type path_and_data :: {Path.t(), binary()}
  @type serialized :: [path_and_data | Path.t()]

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    root_dir = Keyword.get(args, :root_dir, @root_dir)
    sleep_time = Keyword.get(args, :sleep_time, @sleep_time)
    _ = File.mkdir_p!(root_dir)

    bot_state =
      case Keyword.get(args, :bot_state) do
        nil -> BotState.subscribe()
        pid -> BotState.subscribe(pid)
      end

    {:ok, %{root_dir: root_dir, bot_state: bot_state, sleep_time: sleep_time}}
  end

  def handle_info(:timeout, %{bot_state: bot_state} = state) do
    bot_state
    |> serialize_state(state.root_dir)
    |> write_state()

    {:noreply, state}
  end

  def handle_info({BotState, change}, state) do
    new_bot_state = Ecto.Changeset.apply_changes(change)
    # Delay before serializing to the fs to avoid rapid changes
    # causing IO bottleneck
    {:noreply, %{state | bot_state: new_bot_state}, state.sleep_time}
  end

  @spec write_state(serialized) :: :ok
  def write_state(files) do
    files
    |> Enum.each(fn data ->
      case data do
        {path, value} ->
          _ = File.mkdir_p(Path.dirname(path))
          :ok = File.write!(path, value)

        dir ->
          _ = File.mkdir_p(dir)
      end
    end)
  end

  @spec serialize_state(map(), Path.t(), serialized()) :: serialized()
  def serialize_state(bot_state, prefix, acc \\ [])

  def serialize_state(%_struct_type{} = itm, prefix, acc) do
    serialize_state(Map.from_struct(itm), prefix, acc)
  end

  def serialize_state(%{} = bot_state, prefix, acc) do
    Enum.reduce(bot_state, acc, fn {key, value}, acc ->
      cond do
        is_map(value) && map_size(value) == 0 ->
          [Path.join(prefix, to_string(key)) | acc]

        match?(%DateTime{}, value) ->
          [{Path.join(prefix, to_string(value)), to_string(value)} | acc]

        is_map(value) ->
          serialize_state(value, Path.join(prefix, to_string(key)), acc)

        is_number(value) ->
          [{Path.join(prefix, to_string(key)), to_string(value)} | acc]

        is_binary(value) ->
          [{Path.join(prefix, to_string(key)), to_string(value)} | acc]

        is_atom(value) ->
          [{Path.join(prefix, to_string(key)), to_string(value)} | acc]

        is_boolean(value) ->
          [{Path.join(prefix, to_string(key)), to_string(value)} | acc]

        is_nil(value) ->
          [{Path.join(prefix, to_string(key)), <<0x0>>} | acc]

        is_list(value) ->
          Logger.error("Arrays can not be serialized to filesystem nodes")
          acc
      end
    end)
  end
end
