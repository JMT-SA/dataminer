# frozen_string_literal: true

class DataminerConnections
  attr_reader :connections
  def initialize
    @connections = {}
    configs = YAML.load_file(File.join(ENV['ROOT'], 'config', 'dataminer_connections.yml'))
    configs.each_pair do |name, config|
      # Dry Valid? && dry type?
      @connections[name] = DataminerConnection.new(name: name, connection_string: config['db'], report_path: config['path'])
    end
  end

  def [](key)
    connections[key].db
  end

  def report_path(key)
    connections[key].report_path
  end

  def databases
    connections.keys.sort
  end
end

class DataminerConnection
  attr_reader :name, :report_path, :db

  ConnSchema = Dry::Validation.Schema do
    required(:name).value(format?: /\A[\da-z_]+\Z/)
    required(:connection_string).filled
    required(:report_path).filled
  end

  def initialize(config)
    validation = ConnSchema.call(config)
    raise %(Dataminer report config is not correct: #{validation.messages.map { |k, v| "#{k} #{v.join(', ')} (#{validation[k]})" }.join(', ')}) unless validation.success?
    @name = validation[:name]
    @report_path = Pathname.new(validation[:report_path]).expand_path
    @db = Sequel.connect(validation[:connection_string])
  end
end
