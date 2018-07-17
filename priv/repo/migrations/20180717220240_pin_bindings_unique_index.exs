defmodule Farmbot.Repo.Migrations.PinBindingsUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index("pin_bindings", [:pin_num])
  end
end
