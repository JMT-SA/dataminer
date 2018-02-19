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

  # Get the report location path
  #
  # @param id [String] the report id.
  # @return [Crossbeams::Dataminer::Report] the report.
  def admin_report_path
    for_grid_queries ? ENV['GRID_QUERIES_LOCATION'] : ENV['REPORTS_LOCATION']
  end

  # Get a Report from an id.
  #
  # @param id [String] the report id.
  # @return [Crossbeams::Dataminer::Report] the report.
  def lookup_report(id, loc_for_admin = false)
    rep_loc = loc_for_admin ? admin_report_path : ENV['REPORTS_LOCATION']
    DmReportLister.new(rep_loc).get_report_by_id(id)
  end

  # Get an ADMIN Report from an id.
  #
  # @param id [String] the report id.
  # @return [Crossbeams::Dataminer::Report] the report.
  def lookup_admin_report(id)
    lookup_report(id, true)
  end

  # Get a Report's crosstab configuration from an id.
  #
  # @param id [String] the report id.
  # @return [Hash] the crosstab configuration from the report's YAML definition.
  def lookup_crosstab(id, loc_for_admin = false)
    rep_loc = loc_for_admin ? admin_report_path : ENV['REPORTS_LOCATION']
    DmReportLister.new(rep_loc).get_crosstab_hash_by_id(id)
  end
end
