defmodule Farmbot.BotStateNG.LocationData do
  @moduledoc false
  alias Farmbot.BotStateNG.LocationData
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  defmodule Vec3 do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field(:x, :integer)
      field(:y, :integer)
      field(:z, :integer)
    end

    def new do
      %__MODULE__{}
      |> changeset(%{x: -1, y: -1, z: -1})
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

  embedded_schema do
    embeds_one(:scaled_encoders, Vec3)
    embeds_one(:raw_encoders, Vec3)
    embeds_one(:position, Vec3)
  end

  def new do
    %LocationData{}
    |> changeset(%{})
    |> put_embed(:scaled_encoders, Vec3.new(), [])
    |> put_embed(:raw_encoders, Vec3.new(), [])
    |> put_embed(:position, Vec3.new(), [])
    |> apply_changes()
  end

  def view(location_data) do
    %{
      scaled_encoders: Vec3.view(location_data.scaled_encoders),
      raw_encoders: Vec3.view(location_data.raw_encoders),
      position: Vec3.view(location_data.position)
    }
  end

  def changeset(location_data, params \\ %{}) do
    location_data
    |> cast(params, [])
  end
end
