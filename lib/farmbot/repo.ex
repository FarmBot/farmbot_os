defmodule Farmbot.Repo do
  @moduledoc "Storage for Farmbot Resources."
  use Ecto.Repo, otp_app: :farmbot, adapter: Sqlite.Ecto2

  alias Farmbot.Repo.{
    FarmEvent, GenericPointer, Peripheral,
    Point, Regimen, Sequence, ToolSlot, Tool
  }

  @default_syncables [FarmEvent, GenericPointer, Peripheral,
                      Point, Regimen, Sequence, ToolSlot, Tool]

  @doc "A list of all the resources."
  def syncables, do: Application.get_env(:farmbot, :repo)[:farmbot_syncables] || @default_syncables

  @doc "Sync all the modules that export a `sync/1` function."
  def sync!(http \\ Farmbot.HTTP) do
    for syncable <- syncables() do
      if Code.ensure_loaded?(syncable) and function_exported?(syncable, :sync!, 1) do
        spawn fn() ->
          syncable.sync!(http)
        end
        :ok
      end
      :ok
    end
    :ok
  end

end
