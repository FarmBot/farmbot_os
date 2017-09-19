defmodule Farmbot.Repo do
  use Ecto.Repo,
    otp_app: :farmbot,
    adapter: Sqlite.Ecto2
end
