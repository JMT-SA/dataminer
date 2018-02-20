class ReportRepo
  attr_reader :for_grid_queries
  def initialize(for_grid_queries = false)
    @for_grid_queries = for_grid_queries
  end

  # Database connection.
  #
  # @return [Sequel::Database] the database connection.
  def db_connection
    DB # TODO: This may differ from report to report.
  end

  # Get the database connection from DM_CONNECTIONS for a specific key.
  #
  # @param key [String] the database key.
  # @return [Sequel::Database] the database connection.
  def db_connection_for(key)
    DM_CONNECTIONS[key]
  end

  # Get the report location path
  #
  # @param id [String] the report id.
  # @return [Crossbeams::Dataminer::Report] the report.
  def admin_report_path
    for_grid_queries ? ENV['GRID_QUERIES_LOCATION'] : ENV['REPORTS_LOCATION']
  end

  class ReportLocation
    attr_reader :db, :id, :path, :combined

    def initialize(db_id, loc_for_admin = false, for_grid_queries = false)
      @combined = db_id
      @db = db_id.match(/\A(.+?)_/)[1]
      @id = db_id.delete_prefix("#{db}_")
      @path = DM_CONNECTIONS.report_path(@db)
      @path = ENV['GRID_QUERIES_LOCATION'] if loc_for_admin && for_grid_queries
    end
  end

  def split_db_and_id(db_id, loc_for_admin = false)
    rep_loc = ReportLocation.new(db_id, loc_for_admin, for_grid_queries)
    [rep_loc.db, rep_loc.id]
  end

  # Get a Report from an id.
  #
  # @param id [String] the report id.
  # @return [Crossbeams::Dataminer::Report] the report.
  def lookup_report(id, loc_for_admin = false)
    rep_loc = ReportLocation.new(id, loc_for_admin, for_grid_queries)
    p rep_loc
    get_report_by_id(rep_loc)
  end

  # Get a Report's crosstab configuration from an id.
  #
  # @param id [String] the report id.
  # @return [Hash] the crosstab configuration from the report's YAML definition.
  def lookup_crosstab(id, loc_for_admin = false)
    rep_loc = ReportLocation.new(id, loc_for_admin, for_grid_queries)
    get_report_by_id(rep_loc, crosstab_hash: true)
  end

  def lookup_file_name(id, loc_for_admin = false)
    rep_loc = ReportLocation.new(id, loc_for_admin, for_grid_queries)
    get_report_by_id(rep_loc, filename: true)
  end

  def load_report_dictionary(rep_loc)
    get_reports_for(rep_loc.db, rep_loc.path)
  end

  def get_report_by_id(rep_loc, opts = {})
    # config_file       = File.join(rep_loc.path, '.dm_report_list.yml')
    # report_dictionary = YAML.load_file(config_file)
    report_dictionary = load_report_dictionary(rep_loc)
    p report_dictionary
    this_report       = report_dictionary[rep_loc.combined]
    p this_report
    return this_report[:file] if opts[:filename]
    if opts[:crosstab_hash]
      yml = YAML.load_file(this_report[:file])
      return yml[:crosstab]
    end
    persistor = Crossbeams::Dataminer::YamlPersistor.new(this_report[:file])
    Crossbeams::Dataminer::Report.load(persistor)
  end

  # Get an ADMIN Report from an id.
  #
  # @param id [String] the report id.
  # @return [Crossbeams::Dataminer::Report] the report.
  def lookup_admin_report(id)
    lookup_report(id, true)
  end

  def list_all_reports # (options = { from_cache: false, persist: false })
    report_lookup = {}
    DM_CONNECTIONS.databases.each do |key|
      report_lookup.merge!(get_reports_for(key, DM_CONNECTIONS.report_path(key)))
    end
    report_lookup.map { |id, lkp| { id: id, db: lkp[:db], file: lkp[:file], caption: lkp[:caption], crosstab: lkp[:crosstab] } }
    # make_list(options[:from_cache])
    # persist_list if options[:persist]
    # report_lookup.map { |id, lkp| { id: id, file: lkp[:file], caption: lkp[:caption], crosstab: lkp[:crosstab] } }
  end

  def get_reports_for(key, path)
    lkp = {}
    ymlfiles = File.join(path, '**', '*.yml')
    yml_list = Dir.glob(ymlfiles)

    yml_list.each do |yml_file|
      index = "#{key}_#{File.basename(yml_file).sub(File.extname(yml_file), '')}"
      yp    = Crossbeams::Dataminer::YamlPersistor.new(yml_file)
      lkp[index] = { file: yml_file, db: key, caption: Crossbeams::Dataminer::Report.load(yp).caption, crosstab: !yp.to_hash[:crosstab].nil? }
    end
    lkp
  end
end
