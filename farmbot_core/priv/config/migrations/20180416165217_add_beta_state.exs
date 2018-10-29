defmodule Farmbot.Config.Repo.Migrations.AddBetaState do
  use Ecto.Migration
  import Farmbot.Config.MigrationHelpers

  @default_currently_on_beta Application.get_env(:farmbot_core, :default_currently_on_beta)
  if is_nil(@default_currently_on_beta),
    do: raise("Missing application env config: `:default_currently_on_beta`")

  def change do
    create_settings_config("currently_on_beta", :bool, @default_currently_on_beta)
  end
end
