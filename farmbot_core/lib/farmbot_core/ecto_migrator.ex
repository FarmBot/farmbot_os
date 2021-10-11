defmodule FarmbotCore.EctoMigrator do
  @repos [
    FarmbotCore.Config.Repo,
    FarmbotCore.Logger.Repo,
    FarmbotCore.Asset.Repo
  ]

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :migrate, []},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  @doc "Replacement for Mix.Tasks.Ecto.Migrate"
  def migrate do
    IO.puts("=========== BEGIN MIGRATION!")
    for repo <- @repos do
      path = Path.join([:code.priv_dir(:farmbot_core), "asset", "migrations"])
      migrate(repo, path)
    end
    IO.puts("=========== END MIGRATION!")
    :ignore
  end

  def migrate(repo, migrations_path) do
    migrated = Ecto.Migrator.run(repo, migrations_path, :up, [all: true])
    IO.inspect(migrated, label: "======== MIGRATED")
    # pid && repo.stop(pid)
    # restart_apps_if_migrated(apps, migrated)
    Process.sleep(500)
  end

  #   # Pulled this out of Ecto because Ecto's version
  # # messes with Logger config
  # def restart_apps_if_migrated(_, []), do: :ok

  # def restart_apps_if_migrated(apps, [_|_]) do
  #   for app <- Enum.reverse(apps) do
  #     Application.stop(app)
  #   end
  #   for app <- apps do
  #     Application.ensure_all_started(app)
  #   end
  #   :ok
  # end
end
