defmodule FarmbotCore.Config.Repo do
  @moduledoc "Repo for storing config data."
  use Ecto.Repo, otp_app: :farmbot_core, adapter: Ecto.Adapters.SQLite3
end
