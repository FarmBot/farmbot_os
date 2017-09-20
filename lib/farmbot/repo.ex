defmodule Farmbot.Repo do
  use Ecto.Repo, otp_app: :farmbot, adapter: Sqlite.Ecto2

  alias Farmbot.Repo.{
    FarmEvent, Peripheral
  }

  @syncables [FarmEvent, Peripheral]
  def syncables, do: @syncables

  def sync!(http) do
    for syncable <- syncables() do
      syncable.sync!(http)
    end
  end
end
