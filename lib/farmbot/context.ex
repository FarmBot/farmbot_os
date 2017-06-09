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

  defmacro __using__(_) do
    quote do
      alias Farmbot.Context
      alias Farmbot.Context.Tracker
    end
  end

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
  def fetch(%__MODULE__{} = ctx, key), do: Map.fetch(ctx, key)
  def get(%__MODULE__{} = ctx, key, _default), do: Map.fetch(ctx, key)
  def get_and_update(%__MODULE__{}, _, _), do: raise "Cant update #{__MODULE__} struct!"
  def pop(%__MODULE__{}, _), do: raise "Cant pop #{__MODULE__} struct!"

  @typedoc false
  @type database         :: Farmbot.Database.database

  @typedoc false
  @type auth             :: Farmbot.Auth.auth

  @typedoc false
  @type network          :: Farmbot.System.Network.netman

  @typedoc false
  @type serial           :: Farmbot.Serial.Handler.handler

  @typedoc false
  @type hardware         :: Farmbot.BotState.Hardware.hardware

  @typedoc false
  @type monitor          :: Farmbot.BotState.Monitor.monitor

  @typedoc false
  @type configuration    :: Farmbot.BotState.Configuration.configuration

  @typedoc false
  @type http             :: Farmbot.HTTP.http

  @typedoc false
  @type transport        :: Farmbot.Transport.transport

  @typedoc false
  @type farmware_manager :: Farmbot.Farmware.Manager.manager

  @typedoc false
  @type regimen_supervisor :: Farmbot.Regimen.Supervisor.supervisor

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
