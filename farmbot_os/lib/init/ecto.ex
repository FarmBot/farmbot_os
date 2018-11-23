defmodule Farmbot.System.Init.Ecto do
  @moduledoc "Init module for bringup and teardown of ecto."
  use Supervisor

  @doc "This will run migrations on all Farmbot Repos."
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    migrate()
    :ignore
  end

  @doc "Replacement for Mix.Tasks.Ecto.Create"
  def setup do
    repos = Application.get_env(:farmbot, :ecto_repos)

    for repo <- repos do
      Application.put_env(:farmbot, :repo_hack, repo)
      setup(repo)
    end
  end

  def setup(repo) do
    db_file = Application.get_env(:farmbot, repo)[:database]

    unless File.exists?(db_file) do
      :ok = repo.__adapter__.storage_up(repo.config)
    end
  end

  @doc "Replacement for Mix.Tasks.Ecto.Drop"
  def drop do
    repos = Application.get_env(:farmbot, :ecto_repos)

    for repo <- repos do
      case drop(repo) do
        :ok -> :ok
        {:error, :already_down} -> :ok
        {:error, reason} -> raise reason
      end
    end
  end

  def drop(repo) do
    repo.__adapter__.storage_down(repo.config)
  end

  @doc "Replacement for Mix.Tasks.Ecto.Migrate"
  def migrate do
    repos = Application.get_env(:farmbot, :ecto_repos)
    Application.put_env(:farmbot, :repo_hack, nil)

    for repo <- repos do
      Application.put_env(:farmbot, :repo_hack, repo)
      # setup(repo)
      migrate(repo)
    end
  end

  def migrate(Farmbot.Asset.Repo) do
    migrate(Farmbot.Asset.Repo, Path.join([:code.priv_dir(:farmbot_core), "asset", "migrations"]))
  end

  def migrate(Farmbot.Logger.Repo) do
    migrate(Farmbot.Logger.Repo, Path.join([:code.priv_dir(:farmbot_core), "logger", "migrations"]))
  end

  def migrate(Farmbot.Config.Repo) do
    migrate(Farmbot.Config.Repo, Path.join([:code.priv_dir(:farmbot_core), "config", "migrations"]))
  end

  def migrate(repo, migrations_path) do
    opts = [all: true]
    {:ok, pid, apps} = Mix.Ecto.ensure_started(repo, opts)

    migrator = &Ecto.Migrator.run/4
    migrated = migrator.(repo, migrations_path, :up, opts)
    pid && repo.stop(pid)
    Mix.Ecto.restart_apps_if_migrated(apps, migrated)
    Process.sleep(500)
  end
end
