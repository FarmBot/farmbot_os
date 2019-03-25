defmodule FarmbotCore.Asset.Private.Enigma do
  @moduledoc """
  An Enigma is essentially a merge conflict-
  it represents data that has two conflicting
  forms in two different systems (eg: API vs. Bot)
  and requires human intervention to rectify.
  """
  use FarmbotCore.Asset.Schema, path: false

  schema "enigmas" do
    field(:priority, :integer)
    field(:problem_tag, :string)

    field(:monitor, :boolean, defualt: true)
    field(:status, :string, default: "unresolved")
    timestamps()
  end

  def changeset(enigma, params) do
    enigma
    |> cast(params, [:priority, :problem_tag, :status, :monitor])
    |> validate_required([:priority, :problem_tag])
    |> validate_inclusion(:status, ~w(unresolved resolved))
  end

  # This is the public schems.
  # Enigmas are not stored like this internally.
  # Most notibly uuid != local_id
  view enigma do
    %{
      uuid: enigma.local_id,
      priority: enigma.priority,
      problem_tag: enigma.problem_tag,
      created_at: DateTime.to_unix(enigma.created_at)
    }
  end
end
