defmodule FarmbotOS.SysCalls.ResourceUpdate do
  @moduledoc false

  require Logger

  alias FarmbotCore.{
    Asset,
    Asset.Private
  }

  alias FarmbotOS.SysCalls.SendMessage

  @point_kinds ~w(Plant GenericPointer ToolSlot Weed)

  def update_resource("Device", _, params) do
    params
    |> do_handlebars()
    |> Asset.update_device!()
    |> Private.mark_dirty!()

    :ok
  end

  def update_resource(kind, id, params) when kind in @point_kinds do
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
