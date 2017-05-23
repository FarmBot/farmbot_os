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
    :transport
  ]

  @enforce_keys modules
  defstruct [ {:data_stack, []} | modules ]

  defimpl Inspect, for: __MODULE__ do
    def inspect(thing, _) do
      default_context =
        Farmbot.Context.new()
        |> Map.from_struct
        |> Map.delete(:data_stack)

      thing = thing |> Map.from_struct() |> Map.delete(:data_stack)
      if thing == default_context do
        "#Context<default>"
      else
        "#Context<special>"
      end
    end
  end

  @typedoc false
  @type database      :: Farmbot.Database.database

  @typedoc false
  @type auth          :: Farmbot.Auth.auth

  @typedoc false
  @type network       :: Farmbot.System.Network.netman

  @typedoc false
  @type serial        :: Farmbot.Serial.Handler.handler

  @typedoc false
  @type hardware      :: Farmbot.BotState.Hardware.hardware

  @typedoc false
  @type monitor       :: Farmbot.BotState.Monitor.monitor

  @typedoc false
  @type configuration :: Farmbot.BotState.Configuration.configuration

  @typedoc false
  @type http :: Farmbot.HTTP.http

  @typedoc false
  @type transport :: Farmbot.Transport.transport

  @typedoc """
    Stuff to be passed from one CS Node to another
  """
  @type t :: %__MODULE__{
    database:         database,
    auth:             auth,
    network:          network,
    serial:           serial,
    configuration:    configuration,
    monitor:          monitor,
    hardware:         hardware,
    http:             http,
    transport:        transport,
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
  @spec new :: Ast.context
  def new do
    %__MODULE__{ data_stack: [],
                 configuration:    Farmbot.BotState.Configuration,
                 transport:        Farmbot.Transport,
                 hardware:         Farmbot.BotState.Hardware,
                 database:         Farmbot.Database,
                 monitor:          Farmbot.BotState.Monitor,
                 network:          Farmbot.System.Network,
                 serial:           Farmbot.Serial.Handler,
                 auth:             Farmbot.Auth,
                 http:             Farmbot.HTTP
    }
  end
end
