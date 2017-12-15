defmodule Farmbot.Repo.JSONType do
  @moduledoc false
  @behaviour Ecto.Type

  def type, do: :json

  def cast(any), do: {:ok, any}
  def load(value), do: Poison.decode(value, keys: :atoms)
  def dump(value), do: Poison.encode(value)
end
