defmodule FarmbotOS.SysCalls.ResourceUpdate do
  alias FarmbotCore.{
    Asset,
    Asset.Private
  }

  @point_kinds ~w(Plant GenericPointer)

  def resource_update("Device", 0, params) do
    params
    |> Asset.update_device!()
    |> Private.mark_dirty!()

    :ok
  end

  def resource_update(kind, id, params) when kind in @point_kinds do
    point_resource_update(kind, id, params)
  end

  def resource_update(kind, id, _params) do
    {:error,
     """
     Unknown resource: #{kind}.#{id}
     """}
  end

  @doc false
  def point_resource_update(type, id, params) do
    with %{} = point <- Asset.get_point(pointer_type: type, id: id),
         {:ok, point} <- Asset.update_point(point, params) do
      _ = Private.mark_dirty!(point)
      :ok
    else
      nil -> {:error, "#{type}.#{id} is not currently synced, so it could not be updated"}
      {:error, _changeset} -> {:error, "Failed to update #{type}.#{id}"}
    end
  end
end
