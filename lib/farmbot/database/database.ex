defmodule Farmbot.Sync do
  @moduledoc """
    There is a quite a bit of macros going on here.
      * `defdatabase` comes from `Amnesia`
        * defindes a database. This should only show up once.
      * `generate` comes from `Farmbot.Sync.Macros`
        * Should happen once for every syncable object from the api.
        * Needs to be given all the wanted keys that will exist from the api
      * `mutation` comes from `Syncable`
        * takes a key that exists in `generate module`
        * given the variable `before` one can create a new value with that.
        * must return {:ok, new_thing}
  """
  use Amnesia
  import Syncable

  defdatabase Database do
    @moduledoc """
      The Database that holds all the objects found on the Farmbot Web Api
    """

    # Syncables
    syncable Device, [:id, :planting_area_id, :name, :webcam_url]
    syncable Peripheral,
      [:id, :device_id, :pin, :mode, :label, :created_at, :updated_at]
    syncable RegimenItem, [ :id, :time_offset, :regimen_id, :sequence_id]
    syncable Regimen, [:id, :color, :name, :device_id]
    syncable Sequence, [:args, :body, :color, :device_id, :id, :kind, :name]
    syncable ToolBay, [:id, :device_id, :name]
    syncable ToolSlot, [:id, :tool_bay_id, :name, :x, :y, :z]
    syncable Tool, [:id, :slot_id, :name]
    syncable User, [ :id, :device_id, :name, :email, :created_at, :updated_at]
  end
end
