defmodule Farmbot.Asset.PersistentRegimen do
  use Ecto.Schema

  schema "persistent_regimens" do
    # has_one(:regimen, Farmbot.Asset.Regimen)
    # has_one(:farm_event, Farmbot.Asset.FarmEvent)
    field :regimen_id, :id #FIXME
    field :farm_event_id, :id #FIXME
    field :time, :utc_datetime #FIXME?
    timestamps()
  end
end
