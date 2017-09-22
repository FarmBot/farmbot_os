defmodule Farmbot.System.ConfigStorage do
  @moduledoc "Repo for storing config data."
  use Ecto.Repo, otp_app: :farmbot, adapter: Sqlite.Ecto2
end
