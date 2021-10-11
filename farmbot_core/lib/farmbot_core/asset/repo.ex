defmodule FarmbotCore.Asset.Repo do
  @moduledoc "Repo for storing Asset data."
  use Ecto.Repo, otp_app: :farmbot_core, adapter: Ecto.Adapters.SQLite3
end
