defmodule FarmbotCore.Logger.Repo do
  @moduledoc "Repo for storing logs."
  use Ecto.Repo, otp_app: :farmbot_core, adapter: Ecto.Adapters.SQLite3
end
