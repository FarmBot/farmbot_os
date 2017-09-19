defmodule Farmbot.Target.Ecto do
  @moduledoc "Setup the Database."

  @behaviour Farmbot.System.Init
  require Logger

  def start_link(_, _opts) do
    [repo] = Application.get_env(:farmbot, :ecto_repos)

    Logger.info "Dropping DB."
    repo.__adapter__.storage_down(repo.config)

    Logger.info "Creating DB."
    repo.__adapter__.storage_up(repo.config)

    Logger.info "Migrating  DB."
    opts = [all: true]
    {:ok, pid, apps} = Mix.Ecto.ensure_started(repo, opts)

    migrator = &Ecto.Migrator.run/4
    pool = repo.config[:pool]
    migrations_path = Path.join((:code.priv_dir(:farmbot) |> to_string), "repo")
    migrated =
      if function_exported?(pool, :unboxed_run, 2) do
        pool.unboxed_run(repo, fn -> migrator.(repo, migrations_path, :up, opts) end)
      else
        migrator.(repo, migrations_path, :up, opts)
      end

    pid && repo.stop(pid)
    Mix.Ecto.restart_apps_if_migrated(apps, migrated)
    :ignore
  end

end
