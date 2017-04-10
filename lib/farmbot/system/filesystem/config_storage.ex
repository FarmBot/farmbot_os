defmodule Farmbot.System.FS.ConfigStorage do
  @moduledoc """
    Loads information according to a configuration JSON file.
    This does not handle the configuration file, it just holds all the
    information in an easy to reach place.
  """
  use GenServer
  alias Farmbot.System.FS.ConfigFileMigrations, as: CFM
  require Logger

  @config_file Application.get_env(:farmbot, :path) <> "/config.json"
  @default_config_file_name Application.get_env(:farmbot, :config_file_name)
  defp default_config_file,
    do: "#{:code.priv_dir(:farmbot)}/configs/#{@default_config_file_name}"

  def start_link do
    GenServer.start_link(__MODULE__, @config_file, name: __MODULE__)
  end

  def init(path) do
    Logger.info ">> Config Storage init!"
    # Checks if the json file exists or not
    case File.read(path) do
      # if it does parse it
      {:ok, contents} ->
        Logger.info ">> is loading its configuration file: #{path}"
        f = parse_json!(contents)
        migrated = CFM.migrate(f)
        # NOTE(Connor):
        # this will write the initial config file, the migrated one, or
        # the current one at every boot.
        # seems ineffecient but oh well
        write!(migrated)
        Logger.info ">> no migrations"
        {:ok, migrated}
      # if not start over with the default config file (from the priv dir)
      {:error, :enoent} ->
        Logger.info ">> is creating a new configuration file: #{default_config_file()}"
        reset_config()
        init(@config_file)
    end
  end

  def reset_config do
    Farmbot.System.FS.transaction fn() ->
      File.cp!(default_config_file(), @config_file)
    end
  end

  def read_config_file do
    GenServer.call(__MODULE__, :read_config_file)
  end

  @doc """
    Replace the configuration json with a new one.
    BE CAREFUL IM NOT CHECKING THE FILE AT ALL
  """
  @spec replace_config_file(binary | map) :: :ok | {:error, term}
  def replace_config_file(config) when is_map(config) do
    # PLEASE FIXME: This needs to be better validated.
    GenServer.call(__MODULE__, {:replace_config_file, config})
  end

  def replace_config_file(config) when is_binary(config) do
    f = parse_json!(config)
    GenServer.call(__MODULE__, {:replace_config_file, f})
  end

  def handle_call(:read_config_file, _, state) do
    read = File.read(@config_file)
    {:reply, read, state}
  end

  def handle_call({:replace_config_file, new_state}, _, old_state) do
    write!(:ok, new_state)
  end

  def handle_call({:get, module, :all}, _, state) do
    m = module_to_key(module)
    f = state |> Map.get(m)
    {:reply, {:ok, f}, state}
  end

  # GenServer.call(ConfigStorage, {:get, Blah, :uh})
  def handle_call({:get, module, key}, _, state) do
    m = module_to_key(module)
    case state[m] do
      nil ->  {:reply, {:error, :bad_module}, state}
      # this might be a HACK, or it might be clever
      false -> {:reply, {:ok, nil}, state}
      config -> {:reply, {:ok, config[key]}, state}
    end
  end

  def handle_cast({:put, module, {key, val}}, state) do
    m = module_to_key(module)
    old = Map.get(state, m)
    new = Map.put(old, key, val)
    new_state = Map.put(state, m, new)
    write! new_state
  end

  def terminate(_,_), do: nil

  defp module_to_key(module),
    do: module
        |> Module.split
        |> List.last
        |> String.Casing.downcase

  @spec write!(map) :: {:noreply, map}
  defp write!(state) do
    do_write(state)
    {:noreply, state}
  end

  @spec write!(any, map) :: {:reply, any, map}
  defp write!(reply, state) do
    do_write(state)
    {:reply, reply, state}
  end

  defp do_write(state) do
    json = Poison.encode!(state)
    Farmbot.System.FS.transaction fn() ->
      File.write!(@config_file, json)
    end
  end

  # tries to parse contents. raises an exception if it can't
  @spec parse_json!(binary) :: map
  defp parse_json!(contents), do: contents |> Poison.decode!
end
