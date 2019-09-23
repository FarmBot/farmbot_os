defmodule FarmbotOS.SysCalls.ResourceUpdate do
  alias FarmbotCore.{
    Asset,
    Asset.Private
  }

  def resource_update("Device", 0, params) do
    params
    |> Asset.update_device!()
    |> Private.mark_dirty!()

    :ok
  end

  def resource_update("Plant", id, params) do
    with %{} = plant <- Asset.get_point(pointer_type: "Plant", id: id),
         {:ok, plant} <- Asset.update_point(plant, params) do
      _ = Private.mark_dirty!(plant)
      :ok
    else
      nil -> {:error, "Plant.#{id} is not currently synced, so it could not be updated"}
      {:error, _changeset} -> {:error, "Failed to update Plant.#{id}"}
    end
  end

  def resource_update(kind, id, _params) do
    {:error,
     """
     Unknown resource: #{kind}.#{id}
     """}
  end
end
