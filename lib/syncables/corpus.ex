defmodule Corpus do
  defstruct [ tag: nil,
              args: nil,
              nodes: nil ]
 @type t :: %__MODULE__{
   tag: integer,
   args: list(any),
   nodes: list(any)
 }

  @spec create(map) :: t
  def create(%{
    "tag" => tag,
    "args" => args,
    "nodes" => nodes }) do
    %Corpus{
      tag: tag,
      args: args,
      nodes: nodes}
  end
end
