defmodule Farmbot.System.GlobalConfig do
  @moduledoc "Repo for global configuration data."
  use Ecto.Repo, otp_app: :farmbot, adapter: Application.get_env(:farmbot, __MODULE__)[:adapter]
end
