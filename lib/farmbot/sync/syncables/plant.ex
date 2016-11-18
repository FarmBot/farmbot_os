defmodule Plant do
  @moduledoc """
    Dont worry about this.
  """
  defstruct []
  @type t :: %__MODULE__{}
  @spec create(map) :: t
  def create(_map) do
    %Plant{}
  end
end
