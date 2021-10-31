defmodule Farmbot.TestSupport.AssetFixtures do
  alias FarmbotOS.Asset.{
    Device,
    FarmEvent,
    Regimen,
    RegimenInstance,
    Repo,
    Sequence
  }

  def regimen_instance(regimen_params, farm_event_params, params \\ %{}) do
    regimen = regimen(regimen_params)
    farm_event = regimen_event(regimen, farm_event_params)
    params = Map.merge(%{id: :rand.uniform(10000), monitor: false}, params)

    RegimenInstance.changeset(%RegimenInstance{}, params)
    |> Ecto.Changeset.put_assoc(:regimen, regimen)
    |> Ecto.Changeset.put_assoc(:farm_event, farm_event)
    |> Repo.insert!()
  end

  def sequence(params \\ %{}) do
    default = %{
      id: :rand.uniform(10000),
      monitor: false,
      kind: "sequence",
      args: %{locals: %{kind: "scope_declaration", args: %{}}},
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

  @doc """
  Instantiates, but does not create, a %Device{}
  """
  def device_init(params \\ %{}) do
    defaults = %{id: :rand.uniform(1_000_000), monitor: false}
    params = Map.merge(defaults, params)

    Device
    |> struct()
    |> Device.changeset(params)
    |> Ecto.Changeset.apply_changes()
  end
end
