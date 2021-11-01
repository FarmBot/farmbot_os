defmodule FarmbotOS.EctoMigrator do
  require Logger

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
    repo = FarmbotOS.Asset.Repo
    migration_path = Path.join([:code.priv_dir(:farmbot), "repo", "migrations"])
    _ = Ecto.Migrator.run(repo, migration_path, :up, all: true)
    Process.sleep(5000)
    :ignore
  end
end
