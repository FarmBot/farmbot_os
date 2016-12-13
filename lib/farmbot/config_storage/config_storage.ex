alias Farmbot.BotState.Hardware,      as: Hardware
alias Farmbot.BotState.Configuration, as: Configuration
alias Farmbot.BotState.Authorization, as: Authorization
alias Farmbot.BotState.Network,       as: Network
defmodule Farmbot.ConfigStorage do
  @moduledoc """
    Loads information according to a configuration JSON file.
  """

  defmodule Parsed do
    @moduledoc false
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
  alias Farmbot.BotS

  @type args :: String.t

  @spec start_link(args) :: {:ok, pid}
  def start_link(), do: start_link("/tmp/blah.json") # FIXME
  def start_link(path_to_config) do
    GenServer.start_link(__MODULE__, path_to_config, name: __MODULE__)
  end

  @spec init(args) :: {:ok, Parsed.t}
  def init(path_to_config), do: parse_json(path_to_config)

  def handle_call({:get, Authorization, :all}, _, state) do
    f = state.authorization
    {:reply, f, state}
  end

  def handle_call({:get, Authorization, key}, _, state) do
    f =
      state
      |> Map.get(:authorization)
      |> Map.get(key)
    {:reply, f, state}
  end

  def handle_cast({:put, Authorization, {:server, val}}, state) do
    {:noreply, %Parsed{parsed | server: val}}
  end

  def handle_cast({:put, Authorization, {:secret, val}}) do
    {:noreply, %Parsed{parsed | secret: val}}
  end

  # If it can find a file at the given path tries to parse it.
  # If it can not, it loads the default (READ ONLY) one.
  @spec parse_json(args) :: {:ok, Parsed.t} | {:error, term}
  defp parse_json(path_to_config) do
    case File.read(path_to_config) do
      # If the read was successful.
      {:ok, contents} ->
        contents |> Poison.decode! |> parse_json_contents
      # If not.
      _ ->
        default_file |> parse_json
    end
  end

  @spec parse_json_contents(map) :: {:ok, Parsed.t} | {:error, term}
  defp parse_json_contents(
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
         end
  end

  defp parse_json_authorization(%{"secret" => sec, "server" => ser}) do
    {:ok, %{secret: sec, server: ser}}
  end

  defp parse_json_authorization(_), do: {:errror, :authorization}

  defp parse_json_configuration(config) do
    {:ok, config}
  end

  defp parse_json_hardware(%{"params" => params}) do
    {:ok, %{params: params}}
  end

  defp parse_json_hardware(_), do: {:error, :hardware}

  defp parse_json_network(%{}) do
    {:ok, %{}}
  end

  defp parse_json_network(_), do: {:error, :network}


  # Returns the path to the default configuration file.
  @spec default_file :: String.t
  defp default_file,
    do: "#{:code.priv_dir(:farmbot)}/static/default_config.json"

end
