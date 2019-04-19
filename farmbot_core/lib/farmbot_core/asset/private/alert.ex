defmodule FarmbotCore.Asset.Private.Alert do
  @moduledoc """
  An Alert is essentially a merge conflict-
  it represents data that has two conflicting
  forms in two different systems (eg: API vs. Bot)
  and requires human intervention to rectify.

  ## `problem_tag`
  Problem tag should follow a format of: `"author.noun.verb"`
  So for example a fbos alert would could look like:
  * `"farmbot_os.firmware.stalled"`
  * `"farmbot_os.farm_event.conflicted"`
  etc.
  """
  use FarmbotCore.Asset.Schema, path: false

  @author "farmbot_os"
  @known_alerts %{"firmware" => %{"missing" => true}}

  schema "alerts" do
    field(:priority, :integer)
    field(:problem_tag, :string)

    field(:monitor, :boolean, defualt: true)
    field(:status, :string, default: "unresolved")
    timestamps()
  end

  def changeset(alert, params) do
    alert
    |> cast(params, [:priority, :problem_tag, :status, :monitor])
    |> validate_required([:priority, :problem_tag])
    |> validate_problem_tag_format()
    |> validate_inclusion(:status, ~w(unresolved resolved))
  end

  # This is the public schems.
  # Alerts are not stored like this internally.
  # Most notibly uuid != local_id
  view alert do
    %{
      uuid: alert.local_id,
      priority: alert.priority,
      problem_tag: alert.problem_tag,
      created_at: DateTime.to_unix(alert.created_at)
    }
  end

  def validate_problem_tag_format(changeset) do
    {_, tag} = Ecto.Changeset.fetch_field(changeset, :problem_tag)
    case String.split(tag, ".") do
      [@author, noun, verb] ->
        if @known_alerts[noun][verb] do
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
