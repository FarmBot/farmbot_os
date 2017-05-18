defmodule Farmbot.CeleryScript.Ast.Context do
  @moduledoc """
    Context serves as an execution sandbox for all CeleryScript
  """

  alias Farmbot.CeleryScript.Ast

  @enforce_keys [:auth, :database, :network]
  defstruct     [:auth, :database, :network, data_stack: []]

  @typedoc """
    Stuff to be passed from one CS Node to another
  """
  @type t :: %__MODULE__{
    database:   Farmbot.Database.database,
    auth:       Farmbot.Auth.auth,
    network:    Farmbot.System.Network.netman,
    data_stack: [any]
  }

  @spec push_data(t, Ast.t) :: t
  def push_data(%__MODULE__{} = context, %Ast{} = data) do
    new_ds = [data | context.data_stack]
    %{context | data_stack: new_ds}
  end

  @spec pop_data(t) :: {Ast.t, t}
  def pop_data(context) do
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
                 auth:       Farmbot.Auth,
                 network:    Farmbot.System.Network,
                 database:   Farmbot.Database }
  end
end
