defmodule FarmbotOS.BotStateNG.LocationData.Vec3 do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:x, :float)
    field(:y, :float)
    field(:z, :float)
  end

  def new do
    %__MODULE__{}
    |> changeset(%{x: nil, y: nil, z: nil})
    |> apply_changes()
  end

  def view(vec3) do
    %{
      x: vec3.x,
      y: vec3.y,
      z: vec3.z
    }
  end

  def changeset(vec3, params \\ %{}) do
    vec3
    |> cast(params, [:x, :y, :z])
  end
end
