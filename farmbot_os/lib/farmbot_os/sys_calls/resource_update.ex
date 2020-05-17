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
      msg = "Setting #{name} #{property} to #{inspect(v)}"
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
      real_y = point.y

      if params["y"] do
        {desired_y, _} = Float.parse(params["y"])

        if real_y != desired_y do
          FarmbotCore.Logger.error(3, "Y does not match up #{__MODULE__}")
          raise "Y WAS NOT Correct #{inspect({real_y, desired_y})} @@@@"
        else
          IO.puts(
            "                                       point.y = \"#{real_y}\""
          )
        end
      end

      _ = Private.mark_dirty!(point)
      :ok
    else
      nil ->
        msg = "#{type}.#{id} is not currently synced. Please re-sync."
        FarmbotCore.Logger.error(3, msg)
        {:error, msg}

      {:error, _changeset} ->
        msg =
          "Failed update (#{type}.#{id}): Ensure the data is properly formatted"

        FarmbotCore.Logger.error(3, msg)
        {:error, msg}

      err ->
        {:error, "Unknown error. Please notify support. #{inspect(err)}"}
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
