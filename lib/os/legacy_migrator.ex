# TODO: Delete this once FBOS 14.x reaches EOL.
defmodule FarmbotOS.LegacyMigrator do
  import Ecto.Query
  alias FarmbotOS.Config.NetworkInterface
  alias FarmbotOS.Asset.Repo
  require Logger
  @db_path "/root/config-prod.sqlite3"
  @done_flag "/root/v15_migration_done"

  def run(), do: spawn(__MODULE__, :do_run, [])

  def do_run() do
    # Add a sleep for good luck since this runs at boot.
    Process.sleep(10_000)

    if legacy_upgrade?() do
      recover_old_configs()
      if needs_network_config?(), do: recover_network_interfaces()
      finish_upgrade()
    end
  end

  def legacy_upgrade?, do: File.exists?(@db_path) && !File.exists?(@done_flag)

  def needs_network_config? do
    iface_count = Repo.one(from n in "network_interfaces", select: count(n.id))
    iface_count == 0
  end

  def finish_upgrade() do
    File.touch(@done_flag)
    FarmbotOS.System.reboot("Upgrading database...")
  end

  def recover_network_interfaces() do
    # DO NOT SORT THESE!!
    columns = [
      :id,
      :name,
      :type,
      :ssid,
      :psk,
      :security,
      :ipv4_method,
      :migrated,
      :maybe_hidden,
      :ipv4_address,
      :ipv4_gateway,
      :ipv4_subnet_mask,
      :domain,
      :name_servers,
      :regulatory_domain,
      :identity,
      :password
    ]

    # ^ KEY ORDER MATTERS
    {:ok, conn} = Exqlite.Sqlite3.open(@db_path)

    {:ok, statement} =
      Exqlite.Sqlite3.prepare(conn, "SELECT * FROM network_interfaces;")

    result = Exqlite.Sqlite3.step(conn, statement)
    {:row, rows} = result
    iface = Enum.zip(columns, rows) |> Map.new()

    {:ok, _} =
      %NetworkInterface{}
      |> NetworkInterface.changeset(iface)
      |> Repo.insert()
  end

  def recover_old_configs do
    sql_query = """
    SELECT configs.key, string_values.value FROM configs
    INNER JOIN string_values on string_values.id = configs.string_value_id
    WHERE value NOTNULL AND configs.group_id = 1;
    """

    {:ok, conn} = Exqlite.Sqlite3.open(@db_path)
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, sql_query)

    0..10
    |> Enum.map(fn _ -> Exqlite.Sqlite3.step(conn, statement) end)
    |> Enum.reduce(%{}, fn
      {:row, [key, value]}, acc -> Map.put(acc, key, value)
      _step, acc -> acc
    end)
    |> Map.to_list()
    |> Enum.map(fn {key, value} ->
      FarmbotOS.Config.update_config_value(
        :string,
        "authorization",
        key,
        value
      )
    end)
  end
end
