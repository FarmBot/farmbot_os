defmodule FarmbotOS.Asset.Repo.Migrations.RegimenInstanceBug do
  use Ecto.Migration

  def change do
    execute("""
    PRAGMA foreign_keys=off;
    ALTER TABLE regimen_instances RENAME TO old_regimen_instances;
    CREATE TABLE IF NOT EXISTS \"regimen_instances\" (\"local_id\" BINARY_ID PRIMARY KEY,\"started_at\" UTC_DATETIME,\"epoch\" UTC_DATETIME,\"next\" UTC_DATETIME,\"next_sequence_id\" ID,\"regimen_id\" BINARY_ID CONSTRAINT \"persistent_regimens_regimen_id_fkey\" REFERENCES \"regimens\"(\"local_id\"),\"farm_event_id\" BINARY_ID CONSTRAINT \"persistent_regimens_farm_event_id_fkey\" REFERENCES \"farm_events\"(\"local_id\"),\"monitor\" BOOLEAN DEFAULT 1,\"created_at\" UTC_DATETIME NOT NULL,\"updated_at\" UTC_DATETIME NOT NULL);
    INSERT INTO regimen_instances SELECT * FROM old_regimen_instances;
    DROP TABLE old_regimen_instances;
    PRAGMA foreign_keys=on;
    UPDATE farm_events SET updated_at = \'1970-11-07 16:52:31.618000\';
    """)
  end
end
