defmodule Plant do
  defstruct []
 @type t :: %__MODULE__{}
  @spec create(map) :: t
  def create(_map) do
    %Plant{}
  end
end
