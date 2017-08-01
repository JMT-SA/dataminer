class DBConnections
  def db
    @connection ||= make_connection
    @connection
  end

  def make_connection
    Sequel.connect('postgres://postgres:postgres@localhost/kr_framework')
  end

  def base(key = :default)
    db
  end
end
