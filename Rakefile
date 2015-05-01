require 'active_record_migrations'

ActiveRecordMigrations.configure do |c|
  c.database_configuration = {
    'development' => {'adapter' => 'sqlite3',
                      'database' => 'db/db.sqlite3'},
  }
end

ActiveRecordMigrations.load_tasks
