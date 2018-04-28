defmodule Farmbot.System.ConfigStorage.Migrations.FixPersistentRegimensTable do
  use Ecto.Migration

  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.PersistentRegimen
  import Ecto.Query

  def change do
    ConfigStorage.delete_all(from pr in PersistentRegimen, where: is_nil(pr.farm_event_id))
  end
end
