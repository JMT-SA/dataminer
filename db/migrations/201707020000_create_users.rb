Sequel.migration do
  change do
    create_table(:users, ignore_index_errors: true) do
      primary_key :id
      String :login_name, size: 255, null: false
      String :user_name, size: 255
      String :password_hash, size: 255, null: false
      String :email, size: 255
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      
      index [:login_name], name: :users_unique_login_name, unique: true
    end
  end
end
