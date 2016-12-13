defmodule Farmbot.FileSystem.ConfigStorage do
  @moduledoc """
    Loads information according to a configuration JSON file.
  """
  use GenServer
  require Logger

  # This overwrites Elixir.File
  alias Farmbot.FileSystem.File

  @config_file Application.get_env(:farmbot, :state_path) <> "/config.json"
  defp default_config_file,
    do: "#{:code.priv_dir(:farmbot)}/static/default_config.json"

  defmodule Parsed do
    @moduledoc """
      This is what the json file should look like when it hits
      Elixir lands
    """
    @enforce_keys [:authorization, :configuration, :network, :hardware]
    defstruct @enforce_keys
    @type connection :: {String.t, String.t} | :ethernet
    @type t :: %__MODULE__{
      authorization: %{server: String.t, secret: binary},
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
        Logger.debug ">> is loading its configuration file!"
        parse_json!(contents)
      # if not start over with the default config file (from the priv dir)
      _ ->
        Logger.debug ">> is creating a new configuration file!"
        init(default_config_file)
    end
  end

  def handle_call({:get, module, :all}, _, state) do
    m = module_to_key(module)
    f = state |> Map.get(m)
    {:reply, f, state}
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

  def handle_cast({:put, module, {key, var}}, state) do
    # m = module_to_key(module)
    #TODO Fix saving configuration.
    write! state
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
    File.write!(@config_file, json)
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

  defp parse_json_authorization(%{"secret" => sec, "server" => ser}) do
    {:ok, %{secret: sec, server: ser}}
  end

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

  defp parse_json_network(%{}) do
    {:ok, %{}}
  end

  defp parse_json_network(_), do: {:error, :network}
end
