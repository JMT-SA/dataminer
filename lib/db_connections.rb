class DBConnections
  def db
    @connections ||= make_connections
    @connections
  end

  def make_connections
    configuration = ROM::Configuration.new(default: [:sql,
                                                     'postgres://postgres:postgres@localhost/kromco',
                                                     inferrable_relations: []],
                                           warehouse: [:sql,
                                                       'postgres://postgres:postgres@localhost/bookshelf_development',
                                                       inferrable_relations: [:books]])
    rel_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'persistence'))
    configuration.auto_registration(rel_dir, namespace: false)
    ROM.container(configuration)
  end

  def base(key = :default)
    db.gateways[key]
  end
end
