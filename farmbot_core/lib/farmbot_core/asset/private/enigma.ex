defmodule FarmbotCore.Asset.Private.Enigma do
  @moduledoc """
  An Enigma is essentially a merge conflict-
  it represents data that has two conflicting
  forms in two different systems (eg: API vs. Bot)
  and requires human intervention to rectify.
  """
  alias FarmbotCore.Asset.Private.Enigma
  use Ecto.Schema

  @behaviour FarmbotCore.Asset.View
  @primary_key {:uuid, :binary_id, autogenerate: true}

  schema "enigmas" do
    field(:priority, :integer)
    field(:problem_tag, :string)
    field(:created_at,  :utc_datetime)
  end

  @doc false
  def render(%Enigma{} = data) do
    %{
      uuid: data.uuid,
      priority: data.priority,
      problem_tag: data.problem_tag,
      created_at: DateTime.to_unix(data.utc_datetime)
    }
  end
end
