defmodule Farmbot.System.ConfigStorage.GpioRegistry do
  @moduledoc "Union between device (linux) pin and Farmbot Sequence."

  use Ecto.Schema
  import Ecto.Changeset
  alias Farmbot.System.ConfigStorage.GpioRegistry

  schema "gpio_registry" do
    field(:pin, :integer)
    field(:sequence_id, :integer)
  end

  @required_fields [:pin, :sequence_id]

  def changeset(%GpioRegistry{} = gpio, params \\ %{}) do
    gpio
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
