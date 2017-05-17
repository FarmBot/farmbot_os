defmodule Farmbot.CeleryScript.Ast.Context do
  @moduledoc """
    Context serves as an execution sandbox for all CeleryScript
  """

  alias Farmbot.CeleryScript.Ast

  @enforce_keys [:database]
  defstruct [:database, data_stack: []]

  @typedoc """
    Stuff to be passed from one CS Node to another
  """
  @type t :: %__MODULE__{
    database: pid | atom,
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
  @spec new() :: Ast.context
  def new() do
    %__MODULE__{ data_stack: [],
                 database:   Farmbot.Database }
  end
end
