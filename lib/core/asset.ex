defmodule FarmbotOS.Asset do
  @moduledoc """
  Top level module, with some helpers. Persists application resources to disk.
  Submodules of this module usually (but not always) correspond to a
  resource in the REST API. See official REST API docs for details.
  """

  alias FarmbotOS.Asset.{
    CriteriaRetriever,
    Device,
    FarmEvent,
    FarmwareEnv,
    FbosConfig,
    FirmwareConfig,
    Peripheral,
    Point,
    PointGroup,
    Regimen,
    RegimenInstance,
    Repo,
    Sensor,
    SensorReading,
    Sequence,
    Tool
  }

  alias FarmbotOS.ChangeSupervisor

  import Ecto.Query
  require Logger

  ## Begin Device

  def device() do
    Repo.one(Device) || %Device{}
  end

  def device(field) do
    Map.fetch!(device(), field)
  end

  def update_device!(params) do
    device()
    |> Device.changeset(params)
    |> Repo.insert_or_update!()
  end

  def delete_device!(id) do
    if device = Repo.get_by(Device, id: id) do
      Repo.delete!(device)
    end

    :ok
  end

  ## End Device

  ## Begin FarmEvent

  def new_farm_event!(params) do
    %FarmEvent{}
    |> FarmEvent.changeset(params)
    |> Repo.insert!()
  end

  @doc "Returns a FarmEvent by its API id."
  def get_farm_event(id) do
    Repo.get_by(FarmEvent, id: id)
  end

  def update_farm_event!(farm_event, params) do
    farm_event =
      farm_event
      |> FarmEvent.changeset(params)
      |> Repo.update!()

    if farm_event.executable_type == "Regimen" do
      regimen_instance = get_regimen_instance(farm_event)

      if regimen_instance do
        regimen_instance
        |> Repo.preload([:farm_event, :regimen])
        |> RegimenInstance.changeset(%{updated_at: DateTime.utc_now()})
        |> Repo.update!()
      end
    end

    farm_event
  end

  def delete_farm_event!(farm_event) do
    ri = get_regimen_instance(farm_event)
    ri && Repo.delete!(ri)
    Repo.delete!(farm_event)
  end

  def add_execution_to_farm_event!(%FarmEvent{} = farm_event, params \\ %{}) do
    %FarmEvent.Execution{}
    |> FarmEvent.Execution.changeset(params)
    |> Ecto.Changeset.put_assoc(:farm_event, farm_event)
    |> Repo.insert!()
  end

  def get_farm_event_execution(%FarmEvent{} = farm_event, scheduled_at) do
    Repo.all(
      from(e in FarmEvent.Execution,
        where:
          e.farm_event_local_id == ^farm_event.local_id and
            e.scheduled_at == ^scheduled_at,
        limit: 1
      )
    )
    |> Enum.at(0)
  end

  ## End FarmEvent

  ## Begin FbosConfig

  @doc "Gets the local config"
  def fbos_config() do
    Repo.one(FbosConfig) || %FbosConfig{}
  end

  @doc "Gets a field on the local config."
  def fbos_config(field) do
    Map.fetch!(fbos_config(), field)
  end

  @doc """
  This function updates Farmbot OS's local database. It will **NOT** send any
  HTTP requests to the API. To do this, `FarmbotOS.Asset.Private.mark_dirty!/2`
  is almost certainly what you want.
  """
  def update_fbos_config!(fbos_config \\ nil, params) do
    new_data =
      FbosConfig.changeset(fbos_config || fbos_config(), params)
      |> Repo.insert_or_update!()

    ChangeSupervisor.cast_child(new_data, {:new_data, new_data})
    new_data
  end

  def delete_fbos_config!(id) do
    if fbos_config = Repo.get_by(FbosConfig, id: id) do
      Repo.delete!(fbos_config)
    end

    :ok
  end

  ## End FbosConfig

  ## Begin FirmwareConfig

  def firmware_config() do
    Repo.one(FirmwareConfig) || %FirmwareConfig{}
  end

  def firmware_config(field) do
    Map.fetch!(firmware_config(), field)
  end

  def update_firmware_config!(firmware_config \\ nil, params) do
    new_data =
      FirmwareConfig.changeset(firmware_config || firmware_config(), params)
      |> Repo.insert_or_update!()

    ChangeSupervisor.cast_child(new_data, {:new_data, new_data})
    new_data
  end

  def delete_firmware_config!(id) do
    if firmware_config = Repo.get_by(FirmwareConfig, id: id) do
      Repo.delete!(firmware_config)
    end

    :ok
  end

  ## End FirmwareConfig

  ## Begin RegimenInstance

  @doc "returns every regimen instance"
  def list_regimen_instances() do
    RegimenInstance
    |> Repo.all()
    |> Repo.preload([:regimen, :farm_event])
  end

  def get_regimen_instance(%FarmEvent{} = farm_event) do
    regimen =
      Repo.one(from(r in Regimen, where: r.id == ^farm_event.executable_id))

    regimen &&
      Repo.one(
        from(ri in RegimenInstance,
          where:
            ri.regimen_id == ^regimen.local_id and
              ri.farm_event_id == ^farm_event.local_id
        )
      )
  end

  def new_regimen_instance!(%FarmEvent{} = farm_event, params \\ %{}) do
    regimen =
      Repo.one!(from(r in Regimen, where: r.id == ^farm_event.executable_id))

    RegimenInstance.changeset(%RegimenInstance{}, params)
    |> Ecto.Changeset.put_assoc(:regimen, regimen)
    |> Ecto.Changeset.put_assoc(:farm_event, farm_event)
    |> Repo.insert!()
  end

  def delete_regimen_instance!(%RegimenInstance{} = ri) do
    Repo.delete!(ri)
  end

  def add_execution_to_regimen_instance!(%RegimenInstance{} = ri, params \\ %{}) do
    %RegimenInstance.Execution{}
    |> RegimenInstance.Execution.changeset(params)
    |> Ecto.Changeset.put_assoc(:regimen_instance, ri)
    |> Repo.insert!()
  end

  def get_regimen_instance_execution(%RegimenInstance{} = ri, scheduled_at) do
    Repo.all(
      from(e in RegimenInstance.Execution,
        where:
          e.regimen_instance_local_id == ^ri.local_id and
            e.scheduled_at == ^scheduled_at,
        limit: 1
      )
    )
    |> Enum.at(0)
  end

  ## End RegimenInstance

  ## Begin Point

  def get_point(params) do
    Repo.get_by(Point, params)
  end

  def update_point(point, params) do
    # TODO: RC 8 MAY 2020 - We need to hard refresh the point.
    #       The CSVM appears to be caching resources. This leads
    #       to problems when a user runs a sequence that has two
    #       MARK AS steps.
    # NOTE: Updating the `meta` attribute is a _replace_ action
    #       by default, not a merge action.
    # MORE NOTES: Mixed keys (symbol vs. string) will crash this FN.
    #             Let's just stringify everything...
    new_meta = params[:meta] || params["meta"] || %{}
    old_meta = point.meta || %{}
    updated_meta = Map.merge(old_meta, new_meta)

    clean_params =
      params
      |> Map.merge(%{meta: updated_meta})
      |> Enum.map(fn {k, v} -> {"#{k}", v} end)
      |> Map.new()

    Repo.get_by(Point, id: point.id)
    |> Point.changeset(clean_params)
    |> Repo.update()
  end

  @doc "Returns all points matching Point.pointer_type"
  def get_all_points_by_type(type) do
    from(p in Point, where: p.pointer_type == ^type and is_nil(p.discarded_at))
    |> Repo.all()
    |> sort_points("random")
  end

  def nn(ordered, available, from) do
    next_with_distance =
      available
      |> Enum.map(fn p ->
        x = :math.pow(p.x - from.x, 2)
        y = :math.pow(p.y - from.y, 2)
        %{point: p, distance: :math.pow(x + y, 0.5)}
      end)
      |> Enum.sort_by(fn k -> k.distance end)
      |> Enum.at(0)

    next = next_with_distance.point
    new_from = %{x: next.x, y: next.y}
    new_ordered = Enum.concat(ordered, [next])

    new_available =
      available
      |> Enum.filter(fn p -> p.id != next.id end)

    if Enum.count(new_available) == 0 do
      [new_ordered, new_available, new_from]
    else
      nn(new_ordered, new_available, new_from)
    end
  end

  def sort_points(points, "nn") do
    if Enum.count(points) > 0 do
      [ordered, _available, _from] = nn([], points, %{x: 0, y: 0})
      ordered
    else
      points
    end
  end

  def sort_points(points, "xy_alternating") do
    points
    |> Enum.map(fn p -> p.x end)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.with_index(fn x, i ->
      row =
        points
        |> Enum.filter(fn p -> p.x == x end)
        |> Enum.sort_by(fn p -> p.y end)

      if rem(i, 2) == 0 do
        row
      else
        Enum.reverse(row)
      end
    end)
    |> List.flatten()
  end

  def sort_points(points, "yx_alternating") do
    points
    |> Enum.map(fn p -> p.y end)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.with_index(fn y, i ->
      row =
        points
        |> Enum.filter(fn p -> p.y == y end)
        |> Enum.sort_by(fn p -> p.x end)

      if rem(i, 2) == 0 do
        row
      else
        Enum.reverse(row)
      end
    end)
    |> List.flatten()
  end

  def sort_points(points, order_by) do
    points
    |> Enum.group_by(&group_points_by(&1, order_by))
    |> Enum.sort(&group_sort(&1, &2, order_by))
    |> Enum.map(fn {_group_index, group} ->
      Enum.sort(group, &sort_points(&1, &2, order_by))
    end)
    |> List.flatten()
  end

  def group_points_by(%{x: x}, algo)
      when algo in ~w(xy_ascending xy_descending),
      do: x

  def group_points_by(%{y: y}, algo)
      when algo in ~w(yx_ascending yx_descending),
      do: y

  def group_points_by(%{x: x, y: y}, "random"), do: Enum.random([x, y])

  def group_sort({lgroup, _}, {rgroup, _}, "xy_ascending"), do: lgroup <= rgroup
  def group_sort({lgroup, _}, {rgroup, _}, "yx_ascending"), do: lgroup <= rgroup

  def group_sort({lgroup, _}, {rgroup, _}, "xy_descending"),
    do: lgroup >= rgroup

  def group_sort({lgroup, _}, {rgroup, _}, "yx_descending"),
    do: lgroup >= rgroup

  def group_sort(_, _, "random"), do: Enum.random([true, false])

  def sort_points(%{y: ly}, %{y: ry}, "xy_ascending"), do: ly <= ry
  def sort_points(%{y: ly}, %{y: ry}, "xy_descending"), do: ly >= ry
  def sort_points(%{x: lx}, %{x: rx}, "yx_ascending"), do: lx <= rx
  def sort_points(%{x: lx}, %{x: rx}, "yx_descending"), do: lx >= rx
  def sort_points(_, _, "random"), do: Enum.random([true, false])

  ## End Point

  ## Begin PointGroup

  def get_point_group(params) do
    case Repo.get_by(PointGroup, params) do
      nil ->
        nil

      %{sort_type: nil} = group ->
        group

      %{point_ids: unsorted, sort_type: sort_by} = point_group ->
        sorted =
          Repo.all(from(p in Point, where: p.id in ^unsorted))
          |> sort_points(sort_by)
          |> Enum.map(&Map.fetch!(&1, :id))

        %{point_group | point_ids: sorted}
    end
  end

  def find_points_via_group(id) do
    case Repo.get_by(PointGroup, id: id) do
      %{id: _id, sort_type: sort_by} = point_group ->
        # I don't like this because it makes the code
        # harder to understand.
        # We are essentially patching the value of
        # point_group.point_ids with additional IDs.
        # Keep this in mind when debugging sequences
        # that deal with point groups- the point_ids
        # value is not a reflection of what is in
        # the DB / API.
        sorted =
          CriteriaRetriever.run(point_group)
          |> sort_points(sort_by || "xy_ascending")
          |> Enum.map(fn point -> point.id end)

        %{point_group | point_ids: sorted}

      other ->
        # Swallow all other errors
        a = inspect(id)
        b = inspect(other)
        Logger.debug("Unexpected point group #{a} #{b}")
        nil
    end
  end

  def new_point_group!(params) do
    %PointGroup{}
    |> PointGroup.changeset(params)
    |> Repo.insert!()
  end

  def update_point_group!(point_group, params) do
    updated =
      point_group
      |> PointGroup.changeset(params)
      |> Repo.update!()

    regimen_instances = list_regimen_instances()
    farm_events = Repo.all(FarmEvent)

    # check for any matching asset using this point group.
    # This is pretty recursive and probably isn't super great
    # for performance, but SQL can't check this stuff unfortunately.
    for asset <- farm_events ++ regimen_instances do
      # TODO(Connor) this might be worth creating a behaviour for
      if uses_point_group?(asset, point_group) do
        Logger.debug(
          "#{inspect(asset)} uses PointGroup: #{inspect(point_group)}. Reindexing it."
        )

        FarmbotOS.ChangeSupervisor.update_child(asset)
      end
    end

    updated
  end

  def delete_point_group!(%PointGroup{} = point_group) do
    Repo.delete!(point_group)
  end

  def uses_point_group?(%FarmEvent{body: body}, %PointGroup{id: point_group_id}) do
    any_body_node_uses_point_group?(body, point_group_id)
  end

  def uses_point_group?(
        %Regimen{body: body, regimen_items: regimen_items},
        %PointGroup{
          id: point_group_id
        }
      ) do
    any_body_node_uses_point_group?(body, point_group_id) ||
      Enum.find(regimen_items, fn %{sequence_id: sequence_id} ->
        any_body_node_uses_point_group?(
          get_sequence(sequence_id).body,
          point_group_id
        )
      end)
  end

  def uses_point_group?(
        %RegimenInstance{farm_event: farm_event, regimen: regimen},
        point_group
      ) do
    uses_point_group?(farm_event, point_group) ||
      uses_point_group?(regimen, point_group)
  end

  def any_body_node_uses_point_group?(body, point_group_id) do
    Enum.find(body, fn
      %{
        kind: "execute",
        body: execute_body
      } ->
        any_body_node_uses_point_group?(execute_body, point_group_id)

      %{
        args: %{
          "data_value" => %{
            "args" => %{"resource_id" => ^point_group_id},
            "kind" => "point_group"
          },
          "label" => "parent"
        },
        kind: "parameter_application"
      } ->
        true

      %{
        args: %{
          "data_value" => %{
            "args" => %{"point_group_id" => ^point_group_id},
            "kind" => "point_group"
          },
          "label" => "parent"
        },
        kind: "parameter_application"
      } ->
        true

      _ ->
        false
    end)
  end

  ## End PointGroup

  ## Begin Regimen

  @doc "Get a regimen by it's API id"
  def get_regimen(id) do
    Repo.get_by(Regimen, id: id)
  end

  @doc "Enter a new regimen into the DB"
  def new_regimen!(params) do
    %Regimen{}
    |> Regimen.changeset(params)
    |> Repo.insert!()
  end

  def delete_regimen!(regimen) do
    regimen_instances =
      Repo.all(
        from(ri in RegimenInstance, where: ri.regimen_id == ^regimen.local_id)
      )

    for ri <- regimen_instances do
      delete_regimen_instance!(ri)
    end

    Repo.delete!(regimen)
  end

  @doc "Update an existing regimen"
  def update_regimen!(regimen, params) do
    regimen_instances =
      Repo.all(
        from(ri in RegimenInstance, where: ri.regimen_id == ^regimen.local_id)
      )
      |> Repo.preload([:farm_event, :regimen])

    for ri <- regimen_instances do
      ri
      |> RegimenInstance.changeset(%{updated_at: DateTime.utc_now()})
      |> Repo.update!()
    end

    regimen
    |> Regimen.changeset(params)
    |> Repo.update!()
  end

  ## End Regimen

  ## Begin Sequence

  @doc "Get a sequence by it's API id"
  def get_sequence(id) do
    Repo.get_by(Sequence, id: id)
  end

  def update_sequence!(%Sequence{} = sequence, params \\ %{}) do
    sequence_id = sequence.id

    farm_events =
      Repo.all(
        from(f in FarmEvent,
          where:
            f.executable_type == "Sequence" and
              f.executable_id == ^sequence_id
        )
      )

    regimen_instances =
      RegimenInstance
      |> Repo.all()
      |> Repo.preload([:regimen, :farm_event])
      |> Enum.filter(fn
        %{regimen: %{regimen_items: items}} ->
          Enum.find(items, fn
            %{sequence_id: ^sequence_id} -> true
            %{sequence_id: _} -> true
          end)

        %{regimen: nil} ->
          false
      end)

    for asset <- farm_events ++ regimen_instances do
      FarmbotOS.ChangeSupervisor.update_child(asset)
    end

    Sequence.changeset(sequence, params)
    |> Repo.update!()
  end

  def new_sequence!(params \\ %{}) do
    Sequence.changeset(%Sequence{}, params)
    |> Repo.insert!()
  end

  ## End Sequence

  ## Begin FarmwareEnv

  def list_farmware_env() do
    Repo.all(FarmwareEnv)
  end

  def upsert_farmware_env_by_id(id, params) do
    fwe = Repo.get_by(FarmwareEnv, id: id) || %FarmwareEnv{}

    FarmwareEnv.changeset(fwe, params)
    |> Repo.insert_or_update()
  end

  def new_farmware_env(params) do
    key = params["key"] || params[:key]

    fwe =
      with key when is_binary(key) <- key,
           [fwe | _] <-
             Repo.all(from(fwe in FarmwareEnv, where: fwe.key == ^key)) do
        fwe
      else
        _ -> %FarmwareEnv{}
      end

    FarmwareEnv.changeset(fwe, params)
    |> Repo.insert_or_update()
  end

  ## End FarmwareEnv

  ## Begin Peripheral

  def get_peripheral(args) do
    Repo.get_by(Peripheral, args)
  end

  def get_peripheral_by_pin(pin) do
    Repo.get_by(Peripheral, pin: pin)
  end

  ## End Peripheral

  ## Begin Sensor

  def get_sensor(id) do
    Repo.get_by(Sensor, id: id)
  end

  def get_sensor_by_pin(pin) do
    Repo.get_by(Sensor, pin: pin)
  end

  def new_sensor!(params) do
    Sensor.changeset(%Sensor{}, params)
    |> Repo.insert!()
  end

  def update_sensor!(sensor, params) do
    sensor
    |> Sensor.changeset(params)
    |> Repo.update!()
  end

  ## End Sensor

  ## Begin SensorReading

  def get_sensor_reading(id) do
    Repo.get_by(SensorReading, id: id)
  end

  def new_sensor_reading!(params) do
    SensorReading.changeset(%SensorReading{}, params)
    |> Repo.insert!()
  end

  def update_sensor_reading!(sensor_reading, params) do
    sensor_reading
    |> SensorReading.changeset(params)
    |> Repo.update!()
  end

  ## End SensorReading

  ## Begin Tool

  def get_tool(args) do
    Repo.get_by(Tool, args)
  end

  ## End Tool
end
