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
  import Farmbot.Sync.Macros

  defdatabase Database do
    @moduledoc """
      The Database that holds all the objects found on the Farmbot Web Api
    """
    generate Device, [:id, :planting_area_id, :name, :webcam_url] do
      mutation :id do
        IO.inspect before
        {:ok, before}
      end
    end

    generate Ass, [:size, :device] do
      mutation :device do
        Device.validate(before)
      end
    end


  end
end
