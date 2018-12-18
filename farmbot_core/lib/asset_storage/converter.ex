defmodule Farmbot.Asset.Converter do
  alias Asset.{
    Device,
    FarmEvent,
    FarmwareEnv,
    FarmwareInstallation,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    Sensor,
    Sequence,
    Tool,
  }

  @device_fields ~W(id name timezone)
  @farm_events_fields ~W(calendar end_time executable_id executable_type id repeat start_time time_unit)
  @farmware_envs_fields ~W(id key value)
  @farmware_installations_fields ~W(id url first_party)
  @peripherals_fields ~W(id label mode pin)
  @pin_bindings_fields ~W(id pin_num sequence_id special_action)
  @points_fields ~W(id meta name pointer_type tool_id x y z)
  @regimens_fields ~W(farm_event_id id name regimen_items)
  @sensors_fields ~W(id label mode pin)
  @sequences_fields ~W(args body id kind name)
  @tools_fields ~W(id name)

  @doc "Converts data to Farmbot Asset types."
  def to_asset(body, kind) when is_binary(kind) do
    camel_kind = Module.concat(["Farmbot", "Asset",  Macro.camelize(kind)])
    to_asset(body, camel_kind)
  end

  def to_asset(body, Device), do: resource_decode(body, @device_fields, Device)
  def to_asset(body, FarmEvent), do: resource_decode(body, @farm_events_fields, FarmEvent)
  def to_asset(body, FarmwareEnv), do: resource_decode(body, @farmware_envs_fields, FarmwareEnv)
  def to_asset(body, FarmwareInstallation), do: resource_decode(body, @farmware_installations_fields, FarmwareInstallation)
  def to_asset(body, Peripheral), do: resource_decode(body, @peripherals_fields, Peripheral)
  def to_asset(body, PinBinding), do: resource_decode(body, @pin_bindings_fields, PinBinding)
  def to_asset(body, Point), do: resource_decode(body, @points_fields, Point)
  def to_asset(body, Regimen), do: resource_decode(body, @regimens_fields, Regimen)
  def to_asset(body, Sensor), do: resource_decode(body, @sensors_fields, Sensor)
  def to_asset(body, Sequence), do: resource_decode(body, @sequences_fields, Sequence)
  def to_asset(body, Tool), do: resource_decode(body, @tools_fields, Tool)

  defp resource_decode(data, fields, kind) when is_list(data),
    do: Enum.map(data, &resource_decode(&1, fields, kind))

  defp resource_decode(data, fields, kind) do
    data
    |> Map.take(fields)
    |> Enum.map(&string_to_atom/1)
    |> into_struct(kind)
  end

  defp string_to_atom({k, v}), do: {String.to_atom(k), v}
  defp into_struct(data, kind), do: struct(kind, data)
end
