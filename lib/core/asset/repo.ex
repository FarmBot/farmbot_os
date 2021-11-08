defmodule FarmbotOS.Asset.Repo do
  @moduledoc "Repo for storing Asset data."
  use Ecto.Repo, otp_app: :farmbot, adapter: Ecto.Adapters.SQLite3

  # Local IDs are binary now.
  # This causes lots of issues when printing
  # or sending logs to the API. This method exists for
  # safety.
  def encode_local_id(local_id) do
    local_id |> inspect() |> Base.encode64() |> String.slice(0..10)
  end
end
