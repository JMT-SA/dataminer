# require 'dotenv/tasks'
require 'rake/testtask'
require 'rake/clean'
require 'yard'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.warning = false
  t.test_files = FileList['test/**/test_*.rb', 'lib/**/test_*.rb']
end

YARD::Rake::YardocTask.new(:doc) do |t|
  t.files   = ['-', 'README.md']
  t.options = ['-o', "../docs/#{File.dirname(__FILE__).split('/').last}"]
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

task default: :test

namespace :assets do
  desc 'Precompile the assets'
  task :precompile do
    require_relative 'config/environment'
    require './dataminer'
    Dataminer.compile_assets
  end
  CLEAN << 'prestyle.css'
end

# This task ensures Local .env is considered if present:
task :dotenv_with_override do
  require 'dotenv'
  Dotenv.load('.env.local', '.env')
end

namespace :db do
  desc 'Add a new user'
  task :add_user, %i[login_name password user_name] => [:dotenv_with_override] do |_, args|
    raise "\nLogin name cannot include spaces.\n\n" if args[:login_name].include?(' ')
    require 'sequel'
    db_name = "#{ENV.fetch('DATABASE_URL')}#{'_test' if ENV.fetch('RACK_ENV') == 'test'}"
    db = Sequel.connect(db_name)
    id = db[:users].insert(login_name: args[:login_name], user_name: args[:user_name], password_hash: args[:password])
    puts "Created user with id #{id}"
  end

  desc 'Prints current schema version'
  task version: :dotenv_with_override do
    require 'sequel'
    Sequel.extension :migration
    db_name = "#{ENV.fetch('DATABASE_URL')}#{'_test' if ENV.fetch('RACK_ENV') == 'test'}"
    db = Sequel.connect(db_name)
    version = if db.tables.include?(:schema_migrations)
                db[:schema_migrations].reverse(:filename).first[:filename]
              end || 0

    puts "Schema Version: #{version}"
  end

  desc 'Prints previous 10 schema versions'
  task recent_migrations: :dotenv_with_override do
    require 'sequel'
    Sequel.extension :migration
    db_name = "#{ENV.fetch('DATABASE_URL')}#{'_test' if ENV.fetch('RACK_ENV') == 'test'}"
    db = Sequel.connect(db_name)
    migrations = if db.tables.include?(:schema_migrations)
                   db[:schema_migrations].reverse(:filename).first(10).map { |r| r[:filename] }
                 else
                   ['No migrations have been run']
                 end

    puts "Recent migrations:\n#{migrations.join("\n")}"
  end

  desc 'Run migrations'
  task :migrate, [:version] => :dotenv_with_override do |_, args|
    require 'sequel'
    Sequel.extension :migration
    db_name = "#{ENV.fetch('DATABASE_URL')}#{'_test' if ENV.fetch('RACK_ENV') == 'test'}"
    db = Sequel.connect(db_name)
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, 'db/migrations', target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      if ENV['MISS']
        Sequel::Migrator.run(db, 'db/migrations', allow_missing_migration_files: true)
      else
        Sequel::Migrator.run(db, 'db/migrations')
      end
    end
  end

  desc 'Create a new, timestamped migration file - use NAME env var for file name suffix.'
  task :new_migration do
    nm = ENV['NAME']
    raise "\nSupply a filename (to create \"#{Time.now.strftime('%Y%m%d%H%M_create_a_table.rb')}\"):\n\n  rake #{Rake.application.top_level_tasks.last} NAME=create_a_table\n\n" if nm.nil?

    fn = Time.now.strftime("%Y%m%d%H%M_#{nm}.rb")
    File.open(File.join('db/migrations', fn), 'w') do |file|
      file.puts <<~RUBY
        # require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
        Sequel.migration do
          change do
            # Example for create table:
            # create_table(:users, ignore_index_errors: true) do
            #   primary_key :id
            #   String :login_name, size: 255, null: false
            #   String :user_name, size: 255
            #   String :password_hash, size: 255, null: false
            #   String :email, size: 255
            #   TrueClass :active, default: true
            #   DateTime :created_at, null: false
            #   DateTime :updated_at, null: false
            #
            #   index [:login_name], name: :users_unique_login_name, unique: true
            # end
          end
          # Example for setting up created_at and updated_at timestamp triggers:
          # (Change table_name to the actual table name).
          # up do
          #   extension :pg_triggers

          #   pgt_created_at(:table_name,
          #                  :created_at,
          #                  function_name: :table_name_set_created_at,
          #                  trigger_name: :set_created_at)

          #   pgt_updated_at(:table_name,
          #                  :updated_at,
          #                  function_name: :table_name_set_updated_at,
          #                  trigger_name: :set_updated_at)
          # end

          # down do
          #   drop_trigger(:table_name, :set_created_at)
          #   drop_function(:table_name_set_created_at)
          #   drop_trigger(:table_name, :set_updated_at)
          #   drop_function(:table_name_set_updated_at)
          # end
        end
      RUBY
    end
    puts "Created migration #{fn}"
  end

  desc 'Migration to create a new table - use NAME env var for table name.'
  task :create_table_migration do
    nm = ENV['NAME']
    raise "\nYou must supply a table name - e.g. rake #{Rake.application.top_level_tasks.last} NAME=users\n\n" if nm.nil?

    fn = Time.now.strftime("%Y%m%d%H%M_create_#{nm}.rb")
    File.open(File.join('db/migrations', fn), 'w') do |file|
      file.puts <<~RUBY
        require 'sequel_postgresql_triggers'
        Sequel.migration do
          up do
            extension :pg_triggers
            create_table(:#{nm}, ignore_index_errors: true) do
              primary_key :id
              # String :code, size: 255, null: false
              # TrueClass :active, default: true
              DateTime :created_at, null: false
              DateTime :updated_at, null: false
              #
              # index [:code], name: :#{nm}_unique_code, unique: true
            end

            pgt_created_at(:#{nm},
                           :created_at,
                           function_name: :#{nm}_set_created_at,
                           trigger_name: :set_created_at)

            pgt_updated_at(:#{nm},
                           :updated_at,
                           function_name: :#{nm}_set_updated_at,
                           trigger_name: :set_updated_at)

            # Log changes to this table. Exclude changes to the updated_at column.
            run "SELECT audit.audit_table('#{nm}', true, true, '{updated_at}'::text[]);"
          end

          down do
            # Drop logging for this table.
            drop_trigger(:#{nm}, :audit_trigger_row)
            drop_trigger(:#{nm}, :audit_trigger_stm)

            drop_trigger(:#{nm}, :set_created_at)
            drop_function(:#{nm}_set_created_at)
            drop_trigger(:#{nm}, :set_updated_at)
            drop_function(:#{nm}_set_updated_at)
            drop_table(:#{nm})
          end
        end
      RUBY
    end
    puts "Created migration #{fn}"
  end
end
