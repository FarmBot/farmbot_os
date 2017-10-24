defmodule Farmbot.System.ConfigStorage.StringValue do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "string_values" do
    field(:value, :string)
  end

  @required_fields []

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
