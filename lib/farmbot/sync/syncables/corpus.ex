defmodule Corpus do
  @moduledoc """
    Corpus Object
  """
  defstruct [tag: nil,
             args: nil,
             nodes: nil]
  @type t :: %__MODULE__{
   tag: integer,
   args: list(any),
   nodes: list(any)}

  @spec create(map) :: {:ok, t} | {atom, :malformed}
  def create(%{
    "tag" => tag,
    "args" => args,
    "nodes" => nodes}) do
    f = %Corpus{ tag: tag,
                 args: args,
                 nodes: nodes}
    {:ok, f}
  end
  def create(_), do: {__MODULE__, :malformed}
  
  @spec create!(map) :: t
  def create!(thing) do
    case create(thing) do
      {:ok, success} -> success
      {__MODULE__, :malformed} -> raise "Malformed #{__MODULE__} Object"
    end
  end
end
