defmodule Farmbot.Asset do
  @moduledoc """
  Hello Phoenix.
  """

  alias Farmbot.Asset
  alias Asset.{
    Peripheral,
    Sensor
  }

  import Ecto.Query

  @doc "Fetch a Peripheral by its id."
  def get_peripheral(id) do
    repo().one(from p in Peripheral, where: p.id == ^id)
  end

  @doc "Fetch a Sensor by its id."
  def get_sensor(id) do
    repo().one(from s in Sensor, where: s.id == ^id)
  end

  defp repo, do: Farmbot.Repo.current_repo()
end
