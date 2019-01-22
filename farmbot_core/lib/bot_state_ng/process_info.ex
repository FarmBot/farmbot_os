defmodule Farmbot.BotStateNG.ProcessInfo do
  @moduledoc false
  alias Farmbot.BotStateNG.ProcessInfo
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:farmwares, {:map, {:string, :map}}, default: %{})
  end

  def new do
    %ProcessInfo{}
    |> changeset(%{})
    |> apply_changes()
  end

  def view(process_info) do
    %{farmwares: process_info.farmwares}
  end

  def changeset(process_info, params \\ %{}) do
    process_info
    |> cast(params, [:farmwares])
  end
end
