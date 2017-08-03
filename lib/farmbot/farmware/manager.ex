defmodule Farmbot.Farmware.Manager do
  @moduledoc """
    Tracks and manages Farmware
  """
  use Farmbot.Context.Worker
  alias Farmbot.Farmware

  @typedoc false
  @type manager :: atom | pid

  @typedoc false
  @type url    :: binary

  defmodule State do
    @moduledoc false
    defstruct [:context, :farmwares]
    @type t :: %{
      context: Context.t,
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
  @spec lookup_by_name(Context.t, name) :: {:ok, Farmware.t} | {:error, term}
  def lookup_by_name(%Context{farmware_manager: fwt}, name) do
    GenServer.call(fwt, {:lookup_by_name, name})
  end

  @doc "ReIndex the manager."
  @spec reindex(Context.t) :: state
  def reindex(%Context{farmware_manager: fwt}) do
    GenServer.call(fwt, :reindex)
  end

  ## GenServer stuff

  def init(ctx) do
    root_path = "#{Farmbot.System.FS.path()}/farmware/packages"
    Farmbot.System.FS.transaction fn() ->
      File.mkdir_p root_path
    end, true
    installed = root_path |> File.ls!
    fws = Map.new(installed, fn(name) ->
      fw = "#{root_path}/#{name}/manifest.json" |> File.read!() |> Poison.decode! |> Farmware.new
      {fw.name, fw}
    end)

    state = %State{
      context:   ctx,
      farmwares: fws,
    }

    dispatch nil, state
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
    dispatch reply, state
  end

  def handle_call(:reindex, _, state) do
    {:ok, new} = init(state.context)
    dispatch :ok, new
  end

  @spec dispatch(term, state) :: {:reply, term, state}
  defp dispatch(reply, state) do
    GenServer.cast(Farmbot.BotState.Monitor, state)
    {:reply, reply, state}
  end
end
