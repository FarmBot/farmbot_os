defmodule Farmbot.Config.Repo do
  @moduledoc "Repo for storing config data."
  use Ecto.Repo, otp_app: :farmbot_core,
    adapter: Application.get_env(:farmbot_core, __MODULE__)[:adapter]
end
