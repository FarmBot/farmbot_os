alias Farmbot.BotState.Authorization, as: Authorization
alias Farmbot.BotState.Hardware,      as: Hardware
alias Farmbot.BotState.Configuration, as: Configuration
alias Farmbot.BotState.Network,       as: Network
defmodule Farmbot.ConfigStorage do
  @moduledoc """
    Loads information according to a configuration JSON file.
  """

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

  use GenServer
  require Logger

  @type args :: String.t

  @spec start_link(args) :: {:ok, pid}
  def start_link(path_to_config) do
    GenServer.start_link(__MODULE__, path_to_config, name: __MODULE__)
  end

  @spec init(args) :: {:ok, Parsed.t}
  def init(path_to_config), do: parse_json!(path_to_config)

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
    {:noreply, state}
  end

  defp module_to_key(module),
    do: module
        |> Module.split
        |> List.last
        |> String.Casing.downcase
        |> String.to_atom

  # it is expected that this file is here because it was started with the path.
  # Will throw a runtime error if something bad happens.
  @spec parse_json(args) :: {:ok, Parsed.t} | {:error, term}
  defp parse_json!(path_to_config) do
    File.read!(path_to_config) |> Poison.decode! |> parse_json_contents!
  end

  @spec parse_json_contents(map) :: {:ok, Parsed.t} | {:error, term}
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
