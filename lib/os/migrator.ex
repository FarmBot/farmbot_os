defmodule FarmbotOS.EctoMigrator do
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
    repo = FarmbotCore.Asset.Repo
    migration_path = Path.join([:code.priv_dir(:farmbot), "repo", "migrations"])
    migrated = Ecto.Migrator.run(repo, migration_path, :up, [all: true])
    restart_if_migrated(migrated)
    Process.sleep(5000)
    :ignore
  end

  # Pulled this out of Ecto because Ecto's version
  # messes with Logger config
  defp restart_if_migrated([]), do: :ok

  defp restart_if_migrated([_|_]) do
    Application.stop(:farmbot)
    Application.ensure_all_started(:farmbot)
    :ok
  end
end
