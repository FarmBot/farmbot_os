defmodule Farmbot.System.Init.Ecto do
  @moduledoc "Init module for bringup and teardown of ecto."
  use Supervisor
  @behaviour Farmbot.System.Init

  @doc "This will run migrations on all Farmbot Repos."
  def start_link(_, opts \\ []) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    migrate()
    :ignore
  end

  def setup do
    repos = Application.get_env(:farmbot, :ecto_repos)
    for repo <- repos do
      setup(repo)
    end
  end

  def setup(repo) do
    db_file = Application.get_env(:farmbot, repo)[:database]
    unless File.exists?(db_file) do
      :ok = repo.__adapter__.storage_up(repo.config)
    end
  end

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

  @doc "Migrate all repos"
  def migrate do
    repos = Application.get_env(:farmbot, :ecto_repos)
    for repo <- repos do
      # setup(repo)
      migrate(repo)
    end
  end

  def migrate(repo) do
    opts = [all: true]
    {:ok, pid, apps} = Mix.Ecto.ensure_started(repo, opts)

    migrator = &Ecto.Migrator.run/4
    migrations_path =
      (Application.get_env(:farmbot, repo)[:priv] || Path.join((:code.priv_dir(:farmbot) |> to_string), Module.split(repo) |> List.last() |> Macro.underscore()))
      |> Kernel.<>("/migrations")
    migrated = migrator.(repo, migrations_path, :up, opts)
    pid && repo.stop(pid)
    Mix.Ecto.restart_apps_if_migrated(apps, migrated)
  end

  def drop(repo) do
    repo.__adapter__.storage_down(repo.config)
  end
end
