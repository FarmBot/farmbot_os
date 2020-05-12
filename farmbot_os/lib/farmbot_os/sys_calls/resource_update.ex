defmodule FarmbotOS.SysCalls.ResourceUpdate do
  @moduledoc false

  require Logger
  require FarmbotCore.Logger

  alias FarmbotCore.{
    Asset,
    Asset.Private
  }

  alias FarmbotOS.SysCalls.SendMessage

  @point_kinds ~w(Plant GenericPointer ToolSlot Weed)
  @friendly_names %{
    "gantry_mounted" => "`gantry mounted` property",
    "mounted_tool_id" => "mounted tool ID",
    "openfarm_slug" => "Openfarm slug",
    "ota_hour" => "OTA hour",
    "plant_stage" => "plant stage",
    "planted_at" => "planted at time",
    "pullout_direction" => "pullout direction",
    "tool_id" => "tool ID",
    "tz_offset_hrs" => "timezone offset hours",
    "x" => "X axis",
    "y" => "Y axis",
    "z" => "Z axis",
    "Device" => "device",
    "Plant" => "plant",
    "GenericPointer" => "map point",
    "ToolSlot" => "tool slot",
    "Weed" => "weed"
  }

  def notify_user_of_updates(kind, params) do
    Enum.map(params, fn {k, v} ->
      name = @friendly_names[kind] || kind
      property = @friendly_names["#{k}"] || k
      msg = "Setting #{name} #{property} to '#{v}'"
      FarmbotCore.Logger.info(3, msg)
    end)
  end

  def update_resource("Device" = kind, _, params) do
    notify_user_of_updates(kind, params)
    params
    |> do_handlebars()
    |> Asset.update_device!()
    |> Private.mark_dirty!()

    :ok
  end

  def update_resource(kind, id, params) when kind in @point_kinds do
    notify_user_of_updates(kind, params)
    params = do_handlebars(params)
    point_update_resource(kind, id, params)
  end

  def update_resource(kind, id, _params) do
    {:error,
     """
     Unknown resource: #{kind}.#{id}
     """}
  end

  @doc false
  def point_update_resource(type, id, params) do
    with %{} = point <- Asset.get_point(id: id),
         {:ok, point} <- Asset.update_point(point, params) do
      _ = Private.mark_dirty!(point)
      IO.puts("Updated point #{id}: #{inspect(params)}")
      :ok
    else
      nil ->
        {:error,
         "#{type}.#{id} is not currently synced, so it could not be updated"}

      {:error, _changeset} ->
        {:error, "Failed to update #{type}.#{id}"}
    end
  end

  @doc false
  def do_handlebars(params) do
    Map.new(params, fn
      {key, value} when is_binary(value) ->
        case SendMessage.render(value) do
          {:ok, rendered} ->
            {key, rendered}

          _ ->
            Logger.warn(
              "failed to render #{key} => #{value} for update_resource"
            )

            {key, value}
        end

      {key, value} ->
        {key, value}
    end)
  end
end
