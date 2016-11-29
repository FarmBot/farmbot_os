defmodule Plant do
  @moduledoc """
    Dont worry about this.
  """
  defstruct []
  @type t :: %__MODULE__{}
  @spec create(map) :: t
  def create(map) 
  when is_map(map) do
    %Plant{}
  end
  def create(_), do: :error
end
