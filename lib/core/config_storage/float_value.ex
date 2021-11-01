defmodule FarmbotOS.Config.FloatValue do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "float_values" do
    field(:value, :float)
  end

  @required_fields []

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
