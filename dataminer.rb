# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

require 'roda'
require 'rodauth'
require 'crossbeams/dataminer'
# require 'crossbeams/dataminer_interface'
require 'crossbeams/layout'
require 'roda/data_grid'
require 'yaml'
require 'pstore'
require 'base64'
require 'dry/inflector'
require 'dry-struct'
require 'dry-validation'
require 'net/http'
require 'uri'
# require './lib/db_connections'
require 'pry' if ENV.fetch('RACK_ENV') == 'development'

#### require './lib/db_connections'

module Types
  include Dry::Types.module
end

require './lib/crossbeams_responses'
require './lib/repo_base'
require './lib/base_interactor'
require './lib/base_service'
require './lib/local_store' # Will only work for processes running from one dir.
require './lib/ui_rules'
require './lib/library_versions'
require './lib/dataminer_connections'
Dir['./helpers/**/*.rb'].each { |f| require f }
Dir['./lib/applets/*.rb'].each { |f| require f }

ENV['ROOT'] = File.dirname(__FILE__) # Could use Roda.expand_path('.') inside Roda app.
ENV['VERSION'] = File.read('VERSION')
# ENV['REPORTS_LOCATION'] ||= File.expand_path('../../../roda_frame/reports', __FILE__)
# ENV['REPORTS_LOCATION'] ||= File.expand_path('../../label_designer/grid_definitions/dataminer_queries', __FILE__)
ENV['GRID_QUERIES_LOCATION'] ||= File.expand_path('../../label_designer/grid_definitions/dataminer_queries', __FILE__)

DM_CONNECTIONS = DataminerConnections.new

class Dataminer < Roda
  include CommonHelpers
  include MenuHelpers
  include DataminerHelpers

  # Store the name of this class for use in scaffold generating.
  ENV['RODA_KLASS'] = to_s

  use Rack::Session::Cookie, secret: 'some_not_so_nice_long_random_string_DSKJH4378EYR7EGKUFH', key: '_dataminer_session'
  use Rack::MethodOverride # Use with all_verbs plugin to allow 'r.delete' etc.

  plugin :data_grid, path: File.dirname(__FILE__),
                     list_url: '/list/%s/grid',
                     list_nested_url: '/list/%s/nested_grid',
                     list_multi_url: '/list/%s/grid_multi',
                     search_url: '/search/%s/grid',
                     filter_url: '/search/%s',
                     run_search_url: '/search/%s/run',
                     run_to_excel_url: '/search/%s/xls'
  plugin :all_verbs
  plugin :render
  plugin :partials
  plugin :assets, css: 'style.scss', precompiled: 'prestyle.css', sri: nil # SRI: nil because integrity calculated incorrectly....
  plugin :public # serve assets from public folder.
  plugin :multi_route
  plugin :content_for, append: true

  # use Crossbeams::DataminerInterface::App, url_prefix: 'dataminer/',
  #                                          dm_reports_location: File.expand_path('../../../roda_frame/reports', __FILE__),
  #                                          # dm_grid_queries_location: File.expand_path('../../framework/grid_definitions/dataminer_queries', __FILE__),
  #                                          dm_grid_queries_location: File.expand_path('../../label_designer/grid_definitions/dataminer_queries', __FILE__),
  #                                          dm_js_location: 'js',
  #                                          dm_css_location: 'css',
  #                                          db_connection: DB
  plugin :symbolized_params    # - automatically converts all keys of params to symbols.
  plugin :flash
  plugin :csrf, raise: true, skip_if: ->(_) { ENV['RACK_ENV'] == 'test' } # , :skip => ['POST:/report_error'] # FIXME: Remove the +raise+ param when going live!
  plugin :json_parser
  plugin :rodauth do
    db DB
    enable :login, :logout # , :change_password
    logout_route 'a_dummy_route' # Override 'logout' route so that we have control over it.
    # logout_notice_flash 'Logged out'
    session_key :user_id
    login_param 'login_name' # 'user_name'
    login_label 'Login name'
    login_column :login_name # :user_name
    accounts_table :users
    account_password_hash_column :password_hash # :hashed_password (This is old base64 version)
    # require_bcrypt? false
    # password_match? do |password| # Use legacy password hashing. Maybe change this to modern bcrypt using extra new pwd field?
    #   account[:hashed_password] == Base64.encode64(password)
    # end
    # title_instance_variable :@title
    # if DEMO_MODE
    #   before_change_password{r.halt(404)}
    # end
  end
  Dir['./routes/*.rb'].each { |f| require f }

  route do |r|
    r.assets unless ENV['RACK_ENV'] == 'production'
    r.public

    r.rodauth
    rodauth.require_authentication
    r.redirect('/login') if current_user.nil? # Session might have the incorrect user_id

    r.root do
      r.redirect '/dataminer/reports'
    end

    r.multi_route

    r.on 'iframe', Integer do |id|
      repo = SecurityApp::MenuRepo.new
      pf = repo.find_program_function(id)
      view(inline: %(<iframe src="#{pf.url}" title="#{pf.program_function_name}" width="100%" style="height:80vh"></iframe>))
    end

    r.is 'logout' do
      rodauth.logout
      flash[:notice] = 'Logged out'
      r.redirect('/login')
    end

    r.is 'versions' do
      versions = LibraryVersions.new(:layout,
                                     :dataminer,
                                     :datagrid,
                                     :ag_grid,
                                     :selectr,
                                     :sortable,
                                     :lodash,
                                     :multi,
                                     :sweetalert)
      @layout = Crossbeams::Layout::Page.build do |page, _|
        page.section do |section|
          section.add_text('Gem and Javascript library versions', wrapper: :h2)
          section.add_table(versions.to_a, versions.columns, alignment: { version: :right })
        end
      end
      view('crossbeams_layout_page')
    end

    r.is 'not_found' do
      response.status = 404
      view(inline: '<div class="crossbeams-error-note"><strong>Error</strong><br>The requested resource was not found.</div>')
    end

    # Generic grid lists.
    r.on 'list' do
      r.on :id do |id|
        r.is do
          session[:last_grid_url] = "/list/#{id}"
          show_page { render_data_grid_page(id) }
        end

        r.on 'with_params' do
          if fetch?(r)
            show_partial { render_data_grid_page(id, query_string: request.query_string) }
          else
            session[:last_grid_url] = "/list/#{id}/with_params?#{request.query_string}"
            show_page { render_data_grid_page(id, query_string: request.query_string) }
          end
        end

        r.on 'multi' do
          if fetch?(r)
            show_partial { render_data_grid_page_multiselect(id, params) }
          else
            show_page { render_data_grid_page_multiselect(id, params) }
          end
        end

        r.on 'grid' do
          response['Content-Type'] = 'application/json'
          begin
            if params && !params.empty?
              render_data_grid_rows(id, ->(program, permission) { auth_blocked?(program, permission) }, params)
            else
              render_data_grid_rows(id, ->(program, permission) { auth_blocked?(program, permission) })
            end
          rescue StandardError => e
            show_json_exception(e)
          end
        end

        r.on 'grid_multi', String do |key|
          response['Content-Type'] = 'application/json'
          begin
            render_data_grid_multiselect_rows(id, ->(program, permission) { auth_blocked?(program, permission) }, key, params)
          rescue StandardError => e
            show_json_exception(e)
          end
        end
      end
    end

    r.on 'print_grid' do
      @layout = Crossbeams::Layout::Page.build(grid_url: params[:grid_url]) do |page, _|
        page.add_grid('crossbeamsPrintGrid', params[:grid_url], caption: 'Print', for_print: true)
      end
      view('crossbeams_layout_page', layout: 'print_layout')
    end

    # Generic code for grid searches.
    r.on 'search' do
      r.on :id do |id|
        r.is do
          render_search_filter(id, params)
        end

        r.on 'run' do
          session[:last_grid_url] = "/search/#{id}?rerun=y"
          show_page { render_search_grid_page(id, params) }
        end

        r.on 'grid' do
          response['Content-Type'] = 'application/json'
          render_search_grid_rows(id, params, ->(program, permission) { auth_blocked?(program, permission) })
        end

        r.on 'xls' do
          caption, xls = render_excel_rows(id, params)
          response.headers['content_type'] = 'application/vnd.ms-excel'
          response.headers['Content-Disposition'] = "attachment; filename=\"#{caption.strip.gsub(%r{[/:*?"\\<>\|\r\n]}i, '-') + '.xls'}\""
          response.write(xls) # NOTE: could this use streaming to start downloading quicker?
        rescue Sequel::DatabaseError => e
          view(inline: <<-HTML)
          <p style='color:red;'>There is a problem with the SQL definition of this report:</p>
          <p>Report: <em>#{caption}</em></p>The error message is:
          <pre>#{e.message}</pre>
          <button class="pure-button" onclick="crossbeamsUtils.toggleVisibility('sql_code', this);return false">
            <i class="fa fa-info"></i> Toggle SQL
          </button>
          <pre id="sql_code" style="display:none;"><%= sql_to_highlight(@rpt.runnable_sql) %></pre>
          HTML
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
