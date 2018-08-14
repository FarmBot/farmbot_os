defmodule Farmbot.EctoTypes.JSONType do
  @behaviour Ecto.Type
  def type, do: :json
  def cast(any), do: {:ok, any}
  def load(value), do: Farmbot.JSON.decode(value)
  def dump(value), do: Farmbot.JSON.encode(value)
end
