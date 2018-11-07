defmodule Farmbot.Log do
  @moduledoc """
  This is _not_ the same as the API's log asset.
  """

  defmodule LogLevelType do
    @moduledoc false
    @level_atoms [:debug, :info, :error, :warn, :busy, :success, :fun]
    @level_strs ["debug", "info", "error", "warn", "busy", "success", "fun"]

    def type, do: :string

    def cast(level) when level in @level_strs, do: {:ok, level}
    def cast(level) when level in @level_atoms, do: {:ok, to_string(level)}
    def cast(_), do: :error

    def load(str), do: {:ok, String.to_existing_atom(str)}
    def dump(str), do: {:ok, to_string(str)}
  end

  defmodule VersionType do
    @moduledoc false

    def type, do: :string

    def cast(%Version{} = version), do: {:ok, to_string(version)}
    def cast(str), do: {:ok, str}

    def load(str), do: Version.parse(str)
    def dump(str), do: {:ok, to_string(str)}
  end

  defmodule AtomType do
    @moduledoc false

    def type, do: :string

    def cast(atom) when is_atom(atom), do: {:ok, to_string(atom)}
    def cast(str), do: {:ok, str}

    def load(str), do: {:ok, String.to_atom(str)}
    def dump(str), do: {:ok, to_string(str)}
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
    timestamps()
  end

  @required_fields [:level, :verbosity, :message]
  @optional_fields [:meta, :function, :file, :line, :module, :id, :inserted_at, :updated_at]

  def changeset(log, params \\ %{}) do
    log
    |> new()
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def new(%Farmbot.Log{} = merge) do
    merge
    |> Map.put(:version, Version.parse!(Farmbot.Project.version()))
    |> Map.put(:commit, to_string(Farmbot.Project.commit()))
    |> Map.put(:target, to_string(Farmbot.Project.target()))
    |> Map.put(:env, to_string(Farmbot.Project.env()))
  end

  defimpl String.Chars, for: Farmbot.Log do
    def to_string(log) do
      if log.meta[:color] && function_exported?(IO.ANSI, log.meta[:color], 0) do
        "#{apply(IO.ANSI, log.meta[:color], [])}#{log.message}#{color(:normal)}\n"
      else
        "#{color(log.level)}#{log.message}#{color(:normal)}\n"
      end
    end

    defp color(:debug), do: IO.ANSI.light_blue()
    defp color(:info), do: IO.ANSI.cyan()
    defp color(:busy), do: IO.ANSI.blue()
    defp color(:success), do: IO.ANSI.green()
    defp color(:warn), do: IO.ANSI.yellow()
    defp color(:error), do: IO.ANSI.red()
    defp color(:normal), do: IO.ANSI.normal()
    defp color(_), do: IO.ANSI.normal()
  end
end
