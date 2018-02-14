require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    pgt_created_at(:users,
                   :created_at,
                   function_name: :users_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:users,
                   :updated_at,
                   function_name: :users_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:users, :set_created_at)
    drop_function(:users_set_created_at)
    drop_trigger(:users, :set_updated_at)
    drop_function(:users_set_updated_at)
  end
end
