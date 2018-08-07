defmodule Farmbot.InstalledFarmware do
  use Ecto.Schema

  schema "installed_farmwares" do
    field :installed_version, :string
    field :url, :string
    timestamps()
  end
end
