defmodule Farmbot.FarmwareMigration do
  # TODO(Connor) 2018-08-14 Delete this after 6.5.0 is released
  import Farmbot.Config, only: [get_config_value: 3, update_config_value: 4]
  require Farmbot.Logger
  alias Farmbot.Asset.{FarmwareEnv, FarmwareInstallation}

  @doc false
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :migrate, []},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end


  @data_path Application.get_env(:farmbot_ext, :data_path)
  @farmware_dir Path.join(@data_path, "farmware")

  def migrate do
    File.mkdir_p(@farmware_dir)
    if get_config_value(:bool, "settings", "firmware_needs_migration") do
      Farmbot.Logger.busy 1, "Starting Farmware migration."
      migrate_user_env()
      migrate_farmware_installations()
      update_config_value(:bool, "settings", "firmware_needs_migration", false)
      Farmbot.Logger.success 1, "Farmware migrated to the API."
    else
      Farmbot.Logger.debug 3, "Farmware has already been migrated."
    end
    :ignore
  end

  # takes every key/value pair in user_env and turns it
  # into a Farmbot.Asset.FarmwareEnv record.
  def migrate_user_env do
    full_qry = """
    SELECT sv.value  FROM groups g
    LEFT JOIN configs c on (c.group_id == g.id) AND (c.key == "user_env")
    LEFT JOIN string_values sv on sv.id == c.string_value_id
    WHERE g.group_name == "settings"
    """
    %{rows: [[value]]} = Ecto.Adapters.SQL.query!(Farmbot.Config.Repo, full_qry, [])

    value
    |> Farmbot.JSON.decode!()
    |> Enum.map(fn({key, val}) ->
      %FarmwareEnv{key: key, value: val}
    end)
    |> Enum.each(fn(env) ->
      case Farmbot.HTTP.new_farmware_env(env) do
        {:ok, _} ->
          Farmbot.Logger.success 1, "migration task: migrate_user_env '#{env.key}' completed."
        {:error, _} ->
          Farmbot.Logger.error 1, "migration task: migrate_user_env: '#{env.key}' failed."
      end
    end)

    update_config_value(:string, "settings", "user_env", nil)
  end

  def migrate_farmware_installations do
    # Migrate first party stuff.
    qry = "SELECT manifests FROM farmware_repositories"
    %{rows: rows} = Ecto.Adapters.SQL.query!(Farmbot.Config.Repo, qry, [])

    repos = Enum.map(rows, &Farmbot.JSON.decode/1)
    migrated = repos |> Enum.map(&migrate_repo/1) |> List.flatten()

    drop_qry = "DROP TABLE [IF EXISTS] farmware_repositories"
    Ecto.Adapters.SQL.query!(Farmbot.Config.Repo, qry, [])

    # Migrate installed farmwares.
    @farmware_dir
    |> File.ls!()
    |> Kernel.--(migrated)
    |> Enum.map(&Path.join([@farmware_dir, &1, "manifest.json"]))
    |> Enum.map(&File.read!/1)
    |> Enum.map(&Farmbot.JSON.decode!/1)
    |> Enum.map(&Map.take(&1, ["url", "package"]))
    |> Enum.map(&Map.new/1)
    |> migrate_repo()
  end

  def migrate_repo(list, acc \\ [])
  def migrate_repo([], acc), do: Enum.reverse(acc)
  def migrate_repo([%{"manifest" => url, "name" => name} | rest], acc) do
    first_party? = match?("https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/" <> _, url)
    data = %FarmwareInstallation{url: url, first_party: first_party?}
    case Farmbot.HTTP.new_farmware_installation(data) do
      {:ok, _} ->
        Farmbot.Logger.success 1, "migration task: migrate_farmware '#{name}' completed."
      {:error, _} ->
        Farmbot.Logger.error 1, "migration task: migrate_farmware: '#{name}' failed."
    end
    migrate_repo(rest, [name | acc])
  end
end
