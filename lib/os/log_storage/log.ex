defmodule FarmbotOS.Log do
  @moduledoc """
  This is _not_ the same as the API's log asset.
  """
  alias FarmbotOS.{Log, Project}

  defmodule LogLevelType do
    @moduledoc false
    @level_atoms [
      :debug,
      :info,
      :error,
      :warn,
      :busy,
      :success,
      :fun,
      :assertion
    ]
    @level_strs [
      "debug",
      "info",
      "error",
      "warn",
      "busy",
      "success",
      "fun",
      "assertion"
    ]

    def type, do: :string

    def cast(level) when level in @level_strs, do: {:ok, level}
    def cast(level) when level in @level_atoms, do: {:ok, to_string(level)}
    def cast(_), do: :error

    def load(str), do: {:ok, String.to_existing_atom(str)}
    def dump(str), do: {:ok, to_string(str)}
    def equal?(left, right), do: left == right
  end

  defmodule VersionType do
    @moduledoc false

    def type, do: :string

    def cast(%Version{} = version), do: {:ok, to_string(version)}
    def cast(str), do: {:ok, str}

    def load(str), do: Version.parse(str)
    def dump(str), do: {:ok, to_string(str)}
    def equal?(left, right), do: left == right
  end

  defmodule AtomType do
    @moduledoc false

    def type, do: :string

    def cast(atom) when is_atom(atom), do: {:ok, to_string(atom)}
    def cast(str), do: {:ok, str}

    def load(str), do: {:ok, String.to_atom(str)}
    def dump(str), do: {:ok, to_string(str)}
    def equal?(left, right), do: left == right
  end

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "logs" do
    field(:level, LogLevelType)
    field(:verbosity, :integer)
    field(:message, :string)
    field(:meta, :map)
    field(:function, :string)
    field(:file, :string)
    field(:line, :integer)
    field(:module, AtomType)
    field(:version, VersionType)
    field(:commit, :string)
    field(:target, :string)
    field(:env, :string)
    field(:duplicates, :integer, default: 0)
    timestamps()
  end

  @required_fields [:level, :verbosity, :message]
  @optional_fields [
    :meta,
    :function,
    :file,
    :line,
    :module,
    :id,
    :inserted_at,
    :updated_at,
    :duplicates
  ]

  def changeset(log, params \\ %{}) do
    log
    |> new()
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def new(%Log{} = merge) do
    merge
    |> Map.put(:version, Version.parse!(Project.version()))
    |> Map.put(:commit, to_string(Project.commit()))
    |> Map.put(:target, to_string(Project.target()))
    |> Map.put(:env, to_string(Project.env()))
  end

  defimpl String.Chars, for: Log do
    def to_string(log) do
      IO.iodata_to_binary(log.message)
    end
  end
end
