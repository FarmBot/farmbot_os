defmodule Farmbot.FarmwareMigration do
  # TODO(Connor) 2018-08-14 Delete this after 6.5.0 is released
  import Farmbot.Config, only: [get_config_value: 3, update_config_value: 4]
  require Farmbot.Logger
  alias Farmbot.CeleryScript.AST

  @data_path Application.get_env(:farmbot_ext, :data_path)
  @farmware_dir Path.join(@data_path, "farmware")

  def migrate do
    if get_config_value(:bool, "settings", "firmware_needs_migration") do
      migrate_user_env()
      migrate_farmware_installations()
      update_config_value(:bool, "settings", "firmware_needs_migration", false)
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
    %{rows: [[value]]} = Ecto.Adapters.SQL.query!(Farmbot.Config.Repo, qry, [])

    Ecto.Adapters.SQL.query!(Farmbot.System.ConfigStorage, qry, [])

    data = Farmbot.JSON.decode!(value)
    pairs = Enum.map(data, fn({key, value}) ->
      %AST{kind: :pair, args: %{key: key, value: value}, body: []}
    end)
    body = %AST{kind: :set_user_env, args: %{}, body: pairs}
    rpc = %AST{kind: :rpc_request, args: %{label: "migrate_user_env"}, body: body}
    Farmbot.Core.CeleryScript.rpc_request(rpc, &log_results/1)
    update_config_value(:string, "settings", "user_env", nil)
  end

  def migrate_farmware_installations do
    # Migrate first party stuff.
    qry = "SELECT manifests FROM farmware_repositories"
    %{rows: rows} = Ecto.Adapters.SQL.query!(Farmbot.Config, qry, [])

    repos = Enum.map(rows, &Farmbot.JSON.decode/1)
    migrated = repos |> Enum.map(&migrate_repo/1) |> List.flatten()

    drop_qry = "DROP TABLE [IF EXISTS] farmware_repositories"
    Ecto.Adapters.SQL.query!(Farmbot.Config, qry, [])

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
  def migrate_repo([]), do: :ok
  def migrate_repo([%{"manifest" => url, "name" => name} | rest], acc) do
    first_party? = match?("https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/" <> _, url)
    data = Farmbot.JSON.encode(%{first_party: first_party?, url: url})
    case Farmbot.HTTP.post("/api/farmware_installations/", data) do
      {:ok, _} ->
        Farmbot.Logger.success 1, "migration task: migrate_farmware '#{name}' completed."
      {:error, _} ->
        Farmbot.Logger.error 1, "migration task: migrate_farmware: '#{name}' failed."
    end
    migrate_repo(rest, [name | acc])
  end

  defp log_results(%AST{kind: :rpc_ok, args: %{label: label}}) do
    Farmbot.Logger.success 1, "migration task: #{label} completed."
  end

  defp log_results(%AST{kind: :rpc_error, args: %{label: label}, body: [expl]}) do
    %AST{kind: :explanation, args: %{message: message}} = message
    Farmbot.Logger.error 1, "migration task: #{label} failed: #{message}"
  end
end
