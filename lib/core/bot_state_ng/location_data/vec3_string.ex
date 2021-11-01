defmodule FarmbotOS.BotStateNG.LocationData.Vec3String do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:x, :string)
    field(:y, :string)
    field(:z, :string)
  end

  def new do
    %__MODULE__{}
    |> changeset(%{x: "unknown", y: "unknown", z: "unknown"})
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
