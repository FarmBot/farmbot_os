require 'active_record_migrations'
require 'rake/testtask'

ActiveRecordMigrations.configure do |c|
  c.database_configuration = {
    'development' => {'adapter' => 'sqlite3',
                      'database' => 'db/db.sqlite3'},
  }
  # Other settings:
  # c.schema_format = :sql # default is :ruby
  # c.yaml_config = 'db/config.yml'
  # c.environment = ENV['db']
  # c.db_dir = 'db'
  # c.migrations_paths = ['db/migrate'] # the first entry will be used
  # by the generator
end

ActiveRecordMigrations.load_tasks

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = Dir.glob('test/**/*_test.rb')
end

desc "Run tests"
task :default => :test
