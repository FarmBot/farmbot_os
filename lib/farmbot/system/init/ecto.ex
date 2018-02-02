defmodule Farmbot.System.Init.Ecto do
  @moduledoc "Init module for bringup and teardown of ecto."
  use Supervisor
  @behaviour Farmbot.System.Init

  @doc "This will run migrations on all Farmbot Repos."
  def start_link(_, opts \\ []) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    ensure_multiuser_support()
    migrate()
    :ignore
  end

  @doc "Replacement for Mix.Tasks.Ecto.Create"
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
      (Application.get_env(:farmbot, repo)[:priv] ||
         Path.join(
           :code.priv_dir(:farmbot) |> to_string,
           Module.split(repo) |> List.last() |> Macro.underscore()
         ))
      |> Kernel.<>("/migrations")

    pool = repo.config[:pool]

    migrated =
      if function_exported?(pool, :unboxed_run, 2) do
        pool.unboxed_run(repo, fn -> migrator.(repo, migrations_path, :up, opts) end)
      else
        migrator.(repo, migrations_path, :up, opts)
      end

    pid && repo.stop(pid)
    Mix.Ecto.restart_apps_if_migrated(apps, migrated)
    Process.sleep(500)
  end

  # TODO(Connor) Delete this after 6.3.0 is out.
  # We moved the location of sqlite files, so if we don't move them,
  # New ones will be started and be empty.
  @data_path Application.get_env(:farmbot, :data_path)
  @files_that_need_migration [
    # Host dev
    {"Elixir.Farmbot.Repo.A_dev.sqlite3", "repo-A.sqlite3"},
    {"Elixir.Farmbot.Repo.B_dev.sqlite3", "repo-B.sqlite3"},
    {"Elixir.Farmbot.System.ConfigStorage_dev.sqlite3", "config.sqlite3"},

    # Target dev
    {"config-dev.sqlite3", "config.sqlite3"},
    {"repo-dev-A.sqlite3", "repo-A.sqlite3"},
    {"repo-dev-B.sqlite3", "repo-B.sqlite3"},

    # Target prod
    # This one should be last so it overrites dev
    {"config-prod.sqlite3", "config.sqlite3"},
    {"repo-prod-A.sqlite3", "repo-A.sqlite3"},
    {"repo-prod-B.sqlite3", "repo-B.sqlite3"},
  ]
  use Farmbot.Logger
  defp ensure_multiuser_support do
    for {old, new} <- @files_that_need_migration do
      old_full_path = Path.join(@data_path, old)
      new_full_path = Path.join([@data_path, "users", "default", new])
      case File.rename(old_full_path, new_full_path) do
        :ok -> Logger.info 1, "Migrated: #{old_full_path} -> #{new_full_path}"
        _ -> :ok
      end
    end
  end
end
