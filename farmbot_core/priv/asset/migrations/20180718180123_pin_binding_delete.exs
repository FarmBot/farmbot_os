defmodule Farmbot.Repo.Migrations.PinBindingDelete do
  use Ecto.Migration

  def change do
    execute("DELETE FROM pin_bindings")
  end
end
