defmodule Farmbot.System.ConfigStorage.Config do
  @moduledoc ""

  use Ecto.Schema
  import Ecto.Changeset
  alias Farmbot.System.ConfigStorage

  defmodule ValueType do
    @moduledoc false
    @behaviour Ecto.Type

    @doc "List of all the valid group names."
    @valid_types ["boolean", "number", "string"]

    def type, do: :string

    def cast(data) do
      {:ok, data}
    end

    def load(data) do
      {:ok, data}
    end

    def dump(data) when data in @valid_types do
      {:ok, data}
    end

    def dump(_data) do
      :error
    end
  end

  schema "config_keys" do
    belongs_to :config_group,      ConfigStorage.ConfigGroup
    belongs_to :config_key_id,     ConfigStorage.ConfigKey
    field      :config_value_type, ValueType
    field      :config_value_id,   :id
  end

  @required_fields [:config_group_id, :config_key_id, :config_value_type, :config_value_id]

  def changeset(config_group, params \\ %{}) do
    config_group
    |> cast(params, [:config_value_type])
    |> validate_required(@required_fields)
  end

  def put_config(group, key, type, value) do
    import Ecto.Query, only: [from: 2]
    [group_id] = (from cg in ConfigStorage.ConfigGroup, where: cg.name == ^group, select: cg.id) |> ConfigStorage.all
    [key_id]   = (from k in ConfigStorage.ConfigKey, where: k.name == ^key, select: cg.id) |> ConfigStorage.all
    case (from i in querable, where: i.value)
    %__MODULE__{
      config_group_id:   group_id,
      config_key_id:     key_id,
      config_value_type: type,
      config_value_id:   value_id
    }
    |> insert_or_update
  end

  defp insert_or_update(obj) do

  end
end
