defmodule Farmbot.Repo.Migrations.PinBindingsSpecialAction do
  use Ecto.Migration

  def change do
    alter table("pin_bindings") do
      add(:special_action, :string)
    end
  end
end
