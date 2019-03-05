defmodule FarmbotCore.Config.Repo.Migrations.AddGpioRegistry do
  use Ecto.Migration

  def change do
    create table(:gpio_registry) do
      add(:pin, :integer)
      add(:sequence_id, :integer)
    end
  end
end
