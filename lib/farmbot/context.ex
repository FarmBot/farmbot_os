defmodule Farmbot.Context do
  @moduledoc """
    Context serves as an execution sandbox for all CeleryScript
  """

  alias Farmbot.CeleryScript.Ast

  modules = [
    :auth,
    :database,
    :network,
    :serial,
    :hardware,
    :monitor,
    :configuration,
    :http,
    :transport,
    :farmware_manager,
    :regimen_supervisor
  ]

  @enforce_keys modules
  keys = [{:data_stack, []}, :ref]
  defstruct Enum.concat(keys, modules)

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{ref: ref}, _) when is_reference(ref) do
      "#Reference<" <> rest = inspect ref
      info = String.trim(rest, ">")
      "#Context<#{info}>"
    end

    def inspect(_, _) do
      "#Context<:invalid>"
    end
  end

  @behaviour Access
  @doc false
  def fetch(%__MODULE__{} = ctx, key), do: Map.fetch(ctx, key)
  @doc false
  def get(%__MODULE__{} = ctx, key, _default), do: Map.fetch(ctx, key)
  @doc false
  def get_and_update(%__MODULE__{}, _, _), do: raise "Cant update #{__MODULE__} struct!"
  @doc false
  def pop(%__MODULE__{}, _), do: raise "Cant pop #{__MODULE__} struct!"

  @typedoc false
  @type database           :: Farmbot.Behaviour.Database.server
  @typedoc false
  @type auth               :: Farmbot.Behaviour.Auth.otp_server
  @typedoc false
  @type network            :: Farmbot.Behaviour.Network.server
  @typedoc false
  @type serial             :: Farmbot.Behaviour.Serial.server
  @typedoc false
  @type hardware           :: Farmbot.Behaviour.Hardware.server
  @typedoc false
  @type monitor            :: Farmbot.Behaviour.Monitor.server
  @typedoc false
  @type configuration      :: Farmbot.Behaviour.Configuration.server
  @typedoc false
  @type http               :: Farmbot.Behaviour.HTTP.server
  @typedoc false
  @type transport          :: Farmbot.Behaviour.Transport.server
  @typedoc false
  @type farmware_manager   :: Farmbot.Behaviour.FarmwareManager.server
  @typedoc false
  @type regimen_supervisor :: Farmbot.Behaviour.RegimenSupervisor.server

  @typedoc """
    List of usable modules
  """
  @type modules :: Farmbot.Database |
    Farmbot.Auth |
    Farmbot.System.Network |
    Farmbot.Serial.Handler |
    Farmbot.BotState.Hardware |
    Farmbot.BotState.Monitor |
    Farmbot.BotState.Configuration |
    Farmbot.HTTP |
    Farmbot.Transport |
    Farmbot.Farmware.Manager |
    Farmbot.Regimen.Supervisor

  @typedoc """
    Stuff to be passed from one CS Node to another
  """
  @type t :: %__MODULE__{
    database:           database,
    auth:               auth,
    network:            network,
    serial:             serial,
    configuration:      configuration,
    monitor:            monitor,
    hardware:           hardware,
    http:               http,
    transport:          transport,
    farmware_manager:   farmware_manager,
    ref:                reference,
    regimen_supervisor: regimen_supervisor,
    data_stack:       [Ast.t]
  }

  @spec push_data(t, Ast.t) :: t
  def push_data(%__MODULE__{} = context, %Ast{} = data) do
    new_ds = [data | context.data_stack]
    %{context | data_stack: new_ds}
  end

  @spec pop_data(t) :: {Ast.t, t}
  def pop_data(%__MODULE__{} = context) do
    [result | rest] = context.data_stack
    {result, %{context | data_stack: rest}}
  end

  @doc """
    Returns an empty context object for those times you don't care about
    side effects or execution.
  """
  @spec new :: Context.t
  def new do
    %__MODULE__{ data_stack: [],
                 ref:        make_ref(),
                 regimen_supervisor: Farmbot.Regimen.Supervisor,
                 farmware_manager:   Farmbot.Farmware.Manager,
                 configuration:      Farmbot.BotState.Configuration,
                 transport:          Farmbot.Transport,
                 hardware:           Farmbot.BotState.Hardware,
                 database:           Farmbot.Database,
                 monitor:            Farmbot.BotState.Monitor,
                 network:            Farmbot.System.Network,
                 serial:             Farmbot.Serial.Handler,
                 auth:               Farmbot.Auth,
                 http:               Farmbot.HTTP
    }
  end
end
