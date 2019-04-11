defmodule FarmbotCore.Asset.Private.Enigma do
  @moduledoc """
  An Enigma is essentially a merge conflict-
  it represents data that has two conflicting
  forms in two different systems (eg: API vs. Bot)
  and requires human intervention to rectify.

  ## `problem_tag`
  Problem tag should follow a format of: `"author.noun.verb"`
  So for example a fbos enigma would could look like:
  * `"farmbot_os.firmware.stalled"`
  * `"farmbot_os.farm_event.conflicted"`
  etc.
  """
  use FarmbotCore.Asset.Schema, path: false

  @author "farmbot_os"
  @known_enigmas %{"firmware" => %{"missing" => true}}

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
    |> validate_problem_tag_format()
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

  def validate_problem_tag_format(changeset) do
    {_, tag} = Ecto.Changeset.fetch_field(changeset, :problem_tag)
    case String.split(tag, ".") do
      [@author, noun, verb] ->
        if @known_enigmas[noun][verb] do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :problem_tag, "unknown noun verb combo", noun: noun, verb: verb)
        end
      _ ->
        Ecto.Changeset.add_error(changeset, :problem_tag, "invalid format")

    end
  end

  def firmware_missing, do: Enum.join([@author, "firmware", "missing"], ".")
end
