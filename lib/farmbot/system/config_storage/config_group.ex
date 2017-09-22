defmodule Farmbot.System.ConfigStorage.ConfigGroup do
  @moduledoc false

  defmodule Name do
    @moduledoc false
    @behaviour Ecto.Type

    @doc "List of all the valid group names."
    @group_names ["network", "authorization", "hardware", "hardware_params", "settings"]

    def type, do: :string

    def cast(data) do
      {:ok, data}
    end

    def load(data) do
      {:ok, data}
    end

    def dump(data) when data in @group_names do
      {:ok, data}
    end

    def dump(_data) do
      :error
    end
  end

  use Ecto.Schema
  import Ecto.Changeset

  schema "config_groups" do
    field :name, Name
  end

  @required_fields [:name]

  def changeset(config_group, params \\ %{}) do
    config_group
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
