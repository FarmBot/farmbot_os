defmodule Farmbot.TestSupport.AssetFixtures do
  alias Farmbot.Asset.{Repo, Sequence, Regimen, FarmEvent}

  def sequence(params \\ %{}) do
    Sequence
    |> struct()
    |> Sequence.changeset(
      Map.merge(%{id: :rand.uniform(10000), kind: "sequence", args: %{}, body: []}, params)
    )
    |> Repo.insert!()
  end

  def regimen(params \\ %{}) do
    Regimen
    |> struct()
    |> Regimen.changeset(Map.merge(%{id: :rand.uniform(10000), regimen_items: []}, params))
    |> Repo.insert!()
  end

  def regimen_event(regimen, params \\ %{}) do
    now = DateTime.utc_now()

    params =
      Map.merge(
        %{
          id: :rand.uniform(1_000_000),
          executable_type: "Regimen",
          executable_id: regimen.id,
          start_time: now,
          end_time: now,
          repeat: 0,
          time_unit: "never"
        },
        params
      )

    FarmEvent
    |> struct()
    |> FarmEvent.changeset(params)
    |> Repo.insert!()
  end

  def sequence_event(sequence, params \\ %{}) do
    now = DateTime.utc_now()

    params =
      Map.merge(
        %{
          id: :rand.uniform(1_000_000),
          executable_type: "Sequence",
          executable_id: sequence.id,
          start_time: now,
          end_time: now,
          repeat: 0,
          time_unit: "never"
        },
        params
      )

    FarmEvent
    |> struct()
    |> FarmEvent.changeset(params)
    |> Repo.insert!()
  end
end
