defmodule Farmbot.FileSystem.ConfigStorage do
  @moduledoc """
    Loads information according to a configuration JSON file.
  """
  use GenServer
  require Logger

  @config_file Application.get_env(:farmbot_filesystem, :path) <> "/config.json"
  @default_config_file_name Application.get_env(:farmbot_filesystem, :config_file_name)
  defp default_config_file,
    do: "#{:code.priv_dir(:farmbot_filesystem)}/static/#{@default_config_file_name}"

  defmodule Parsed do
    @moduledoc """
      This is what the json file should look like when it hits
      Elixir lands
    """
    @enforce_keys [:authorization, :configuration, :network, :hardware]
    defstruct @enforce_keys
    @type connection :: {String.t, String.t} | :ethernet
    @type t :: %__MODULE__{
      authorization: %{server: String.t},
      configuration: %{},
      network: %{connection: connection},
      hardware: %{}
    }
  end
  @type args :: []
  @spec start_link(args) :: {:ok, pid}
  def start_link(), do: start_link([])
  def start_link(_args) do
    GenServer.start_link(__MODULE__, @config_file, name: __MODULE__)
  end

  @spec init(args) :: {:ok, Parsed.t}
  def init(path) do
    # Checks if the json file exists or not
    case File.read(path) do
      # if it does parse it
      {:ok, contents} ->
        Logger.debug ">> is loading its configuration file: #{path}"
        parse_json!(contents)
      # if not start over with the default config file (from the priv dir)
      {:error, :enoent} ->
        Logger.debug ">> is creating a new configuration file: #{default_config_file}"
        Farmbot.FileSystem.transaction fn() ->
          File.cp!(default_config_file, @config_file)
        end
        init(@config_file)
    end
  end

  def read_config_file do
    GenServer.call(__MODULE__, :read_config_file)
  end

  def handle_call(:read_config_file, _, state) do
    read = File.read(@config_file)
    {:reply, read, state}
  end

  def handle_call({:get, module, :all}, _, state) do
    m = module_to_key(module)
    f = state |> Map.get(m)
    {:reply, {:ok, f}, state}
  end

  def handle_call({:get, module, key}, _, state) do
    m = module_to_key(module)
    config_map = Map.get(state, m)
    if is_map(config_map) do
      f = Map.get(config_map, key)
      {:reply, {:ok, f}, state}
    else
      {:reply, {:error, :bad_module}, state}
    end
  end

  def handle_cast({:put, module, {key, val}}, state) do
    m = module_to_key(module)
    old = Map.get(state, m)
    new = Map.put(old, key, val)
    new_state = Map.put(state, m, new)
    write! new_state
  end

  defp module_to_key(module),
    do: module
        |> Module.split
        |> List.last
        |> String.Casing.downcase
        |> String.to_atom

  @spec write!(Parsed.t) :: {:noreply, Parsed.t}
  defp write!(%Parsed{} = state) do
    json = Poison.encode!(state)
    Farmbot.FileSystem.transaction fn() ->
      File.write!(@config_file, json)
    end
    {:noreply, state}
  end

  # tries to parse contents. raises an exception if it can't
  @spec parse_json!(args) :: {:ok, Parsed.t} | {:error, term}
  defp parse_json!(contents),
    do: contents |> Poison.decode! |> parse_json_contents!

  @spec parse_json_contents!(map) :: {:ok, Parsed.t} | {:error, term}
  defp parse_json_contents!(
    %{
      "configuration" => json_configuration,
      "network" => json_network,
      "authorization" => json_authorization,
      "hardware" => json_hardware
    })
  do
    with {:ok, configuration} <- json_configuration |> parse_json_configuration,
         {:ok, network} <- json_network |> parse_json_network,
         {:ok, auth} <- json_authorization |> parse_json_authorization,
         {:ok, hardware} <- json_hardware |> parse_json_hardware
         do
           f =
             %Parsed{authorization: auth,
                     configuration: configuration,
                     hardware: hardware,
                     network: network}
           {:ok, f}
         else
           {:error, reason} ->
             raise "Could not parse json config file! #{inspect reason}"
           e ->
             raise "Could not parse json config file! #{inspect e}"
         end
  end

  defp parse_json_authorization(%{"server" => ser}), do: {:ok, %{server: ser}}

  defp parse_json_authorization(_), do: {:errror, :authorization}

  defp parse_json_configuration(
    %{"os_auto_update" => oau,
      "fw_auto_update" => fau,
      "timezone" => tz,
      "steps_per_mm" => s})
  do
    f = %{
      os_auto_update: oau,
      fw_auto_update: fau,
      timezone: tz,
      steps_per_mm: s
    }
    {:ok, f}
  end

  defp parse_json_hardware(%{"params" => params}) do
    {:ok, %{params: params}}
  end

  defp parse_json_hardware(_), do: {:error, :hardware}

  defp parse_json_network(thing) do
    {:ok, thing}
  end
end
