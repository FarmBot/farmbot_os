defmodule Farmbot.Repo.Sequence do
  @moduledoc """
  A Sequence is a list of CeleryScript nodes.
  """

  alias Farmbot.Repo.JSONType
  use Ecto.Schema
  import Ecto.Changeset

  defmodule CeleryScriptBody do
    @moduledoc "Custom Ecto.Type for convirting text to CelecyScript."
    @behaviour Ecto.Type

    # Cast and Dump will just be forwareded to the JSONType module.
    defdelegate cast(data), to: JSONType
    defdelegate dump(data), to: JSONType
    defdelegate type,       to: JSONType

    def dump(data), do: JSONType.dump(data)

    def load(text) do
      {:ok, data} = text |> JSONType.load()
      res = Enum.map(data, fn(data) ->
        Farmbot.CeleryScript.Ast.parse(data)
      end)
      {:ok, res}
    end

  end

  defmodule CeleryScriptArgs do
    @moduledoc "Custom Ecto.Type for convirting a sequence args to CS args."
    @behaviour Ecto.Type

    # Cast and Dump will just be forwareded to the JSONType module.
    defdelegate cast(data), to: JSONType
    defdelegate dump(data), to: JSONType
    defdelegate type,       to: JSONType

    def load(text) do
      {:ok, data} = text |> JSONType.load()
      res = Farmbot.CeleryScript.Ast.parse_args(data)
      {:ok, res}
    end

  end

  schema "sequences" do
    field :name, :string
    field :kind, :string
    field :args, CeleryScriptArgs
    field :body, CeleryScriptBody
  end

  use Farmbot.Repo.Syncable
  @required_fields [:id, :name, :kind, :args, :body]

  def changeset(sequence, params \\ %{}) do
    sequence
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
