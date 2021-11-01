defmodule FarmbotOS.BotStateNG.LocationData do
  @moduledoc false
  alias FarmbotOS.BotStateNG.LocationData
  alias LocationData.{Vec3, Vec3String}
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    embeds_one(:scaled_encoders, Vec3, on_replace: :update)
    embeds_one(:raw_encoders, Vec3, on_replace: :update)
    embeds_one(:position, Vec3, on_replace: :update)
    embeds_one(:load, Vec3, on_replace: :update)
    embeds_one(:axis_states, Vec3String, on_replace: :update)
  end

  def new do
    %LocationData{}
    |> changeset(%{})
    |> put_embed(:scaled_encoders, Vec3.new(), [])
    |> put_embed(:raw_encoders, Vec3.new(), [])
    |> put_embed(:position, Vec3.new(), [])
    |> put_embed(:load, Vec3.new(), [])
    |> put_embed(:axis_states, Vec3String.new(), [])
    |> apply_changes()
  end

  def view(location_data) do
    %{
      scaled_encoders: Vec3.view(location_data.scaled_encoders),
      raw_encoders: Vec3.view(location_data.raw_encoders),
      position: Vec3.view(location_data.position),
      load: Vec3.view(location_data.load),
      axis_states: Vec3String.view(location_data.axis_states)
    }
  end

  def changeset(location_data, params \\ %{}) do
    location_data
    |> cast(params, [])
    |> cast_embed(:scaled_encoders)
    |> cast_embed(:raw_encoders)
    |> cast_embed(:position)
    |> cast_embed(:load)
    |> cast_embed(:axis_states)
  end
end
