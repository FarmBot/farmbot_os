defmodule Farmbot.TestSupport.AssetFixtures do
  alias Farmbot.Asset
  alias Farmbot.Asset.{Repo, FarmEvent, FbosConfig, Regimen, Sequence}

  def persistent_regimen(regimen_params, farm_event_params, params \\ %{}) do
    regimen = regimen(regimen_params)
    farm_event = regimen_event(regimen, farm_event_params)
    params = Map.merge(%{id: :rand.uniform(10000), monitor: false}, params)
    Asset.upsert_persistent_regimen!(regimen, farm_event, params)
  end

  def fbos_config(params \\ %{}) do
    default = %{
      id: :rand.uniform(10000),
      monitor: false
    }

    FbosConfig
    |> struct()
    |> FbosConfig.changeset(Map.merge(default, params))
    |> Repo.insert!()
  end

  def sequence(params \\ %{}) do
    default = %{
      id: :rand.uniform(10000),
      monitor: false,
      kind: "sequence",
      args: %{},
      body: []
    }

    Sequence
    |> struct()
    |> Sequence.changeset(Map.merge(default, params))
    |> Repo.insert!()
  end

  def regimen(params \\ %{}) do
    default = %{id: :rand.uniform(10000), monitor: false, regimen_items: []}

    Regimen
    |> struct()
    |> Regimen.changeset(Map.merge(default, params))
    |> Repo.insert!()
  end

  def regimen_event(regimen, params \\ %{}) do
    now = DateTime.utc_now()

    params =
      Map.merge(
        %{
          id: :rand.uniform(1_000_000),
          monitor: false,
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
          monitor: false,
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
