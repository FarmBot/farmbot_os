defmodule Farmbot.Farmware.Manager do
  @moduledoc """
  Tracks and manages Farmware
  """
  alias Farmbot.Farmware
  alias Farmbot.BotState.ProcessInfo

  @typedoc false
  @type manager :: GenServer.server

  @typedoc false
  @type url :: binary

  defmodule State do
    @moduledoc false
    defstruct [:bot_state, :process_info, :token, :farmwares]
    @type t :: %{
      bot_state: GenServer.server,
      process_info: GenServer.server,
      token: binary,
      farmwares: %{optional(Farmware.name) => Farmware.t}
    }
  end

  @typedoc false
  @type state :: State.t

  @typedoc "Farmware Name. Should be unique."
  @type name :: Farmware.name

  @doc """
  Lookup a Farmware.
  """
  @spec lookup_by_name(manager, name) :: {:ok, Farmware.t} | {:error, term}
  def lookup_by_name(manager, name) do
    GenServer.call(manager, {:lookup_by_name, name})
  end

  @doc "ReIndex the manager."
  @spec reindex(manager) :: state
  def reindex(manager) do
    GenServer.call(manager, :reindex)
  end

  @doc "Starts the farmware manager."
  def start_link(token, bot_state, process_info, opts \\ []) do
    GenServer.start_link(__MODULE__, [token, bot_state, process_info], opts)
  end

  ## GenServer stuff

  def init([token, bot_state, process_info]) do
    root_path = "./tmp/farmbot/farmware/packages"
    File.mkdir_p root_path
    installed = root_path |> File.ls!
    fws = Map.new(installed, fn(name) ->
      fw = "#{root_path}/#{name}/manifest.json" |> File.read!() |> Poison.decode! |> Farmware.new
      {fw.name, fw}
    end)

    state = %State{
      bot_state: bot_state,
      process_info: process_info,
      token: token,
      farmwares: fws,
    }

    dispatch process_info, nil, state
    {:ok, state}
  end

  def handle_call({:lookup_by_name, name}, _, state) do
    farmwares = state.farmwares
    reply = Enum.find_value(farmwares, {:error, :not_found},
      fn({fw_name, %Farmware{} = fw}) ->
        if fw_name == name do
          {:ok, fw}
        end
      end)
    dispatch state.process_info, reply, state
  end

  def handle_call(:reindex, _, state) do
    {:ok, new} = init([state.token, state.bot_state, state.process_info])
    dispatch state.process_info, :ok, new
  end

  @spec dispatch(GenServer.server, term, state) :: {:reply, term, state}
  defp dispatch(process_info, reply, state) do
    :ok = ProcessInfo.update_farmwares(process_info, state.farmwares)
    {:reply, reply, state}
  end
end
