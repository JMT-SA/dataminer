# frozen_string_literal: true

class Dataminer < Roda
  route 'reports', 'dataminer' do |r|
    interactor = DataminerInteractor.new(current_user, {}, {}, {})

    r.on 'report', String do |id|
      r.get true do
        @page = interactor.report_parameters(id, params)
        view('dataminer/report/parameters')
      end

      r.post 'xls' do
        page = interactor.create_spreadsheet(id, params)
        response.headers['content_type'] = 'application/vnd.ms-excel'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{page.report.caption.strip.gsub(/[\/:*?"\\<>\|\r\n]/i, '-') + '.xls'}\""
        # NOTE: could this use streaming to start downloading quicker?
        response.write(page.excel_file.to_stream.read)
      rescue Sequel::DatabaseError => e
        erb(<<-HTML)
        <p style='color:red;'>There is a problem with the SQL definition of this report:</p>
        <p>Report: <em>#{@rpt.caption}</em></p>The error message is:
        <pre>#{e.message}</pre>
        <button class="pure-button" onclick="crossbeamsUtils.toggleVisibility('sql_code', this);return false">
          <i class="fa fa-info"></i> Toggle SQL
        </button>
        <pre id="sql_code" style="display:none;"><%= sql_to_highlight(@rpt.runnable_sql) %></pre>
        HTML
      end

      r.post 'run' do
        @page = interactor.run_report(id, params)
        view('dataminer/report/display')
      rescue Sequel::DatabaseError => e
        view(inline: <<-HTML)
        <p style='color:red;'>There is a problem with the SQL definition of this report:</p>
        <p>Report: <em>#{@rpt.caption}</em></p>The error message is:
        <pre>#{e.message}</pre>
        <button class="pure-button" onclick="crossbeamsUtils.toggleVisibility('sql_code', this);return false">
          <i class="fa fa-info"></i> Toggle SQL
        </button>
        <pre id="sql_code" style="display:none;"><%= sql_to_highlight(@rpt.runnable_sql) %></pre>
        HTML
      end
    end

    r.is do
      renderer = Crossbeams::Layout::Renderer::Grid.new('rpt_grid', '/dataminer/reports/grid/', 'Report listing')
      view(inline: renderer.render)
    end

    r.on 'grid' do
      response['Content-Type'] = 'application/json'
      interactor.report_list_grid
    end
    # REPORTS
    # --------------------------------------------------------------------------
    r.on 'reports' do
      r.is do
        view(inline: 'Listing here')
      end
      # r.on 'new' do    # NEW
      #   # begin
      #   # if authorised?('menu', 'new')
      #   show_page { Development::Generators::Scaffolds::New.call }
      #   # else
      #   #   show_unauthorised
      #   # end
      #   # Should lead to step 1, 2 etc.
      #   # rescue StandardError => e
      #   #   handle_error(e)
      #   # end
      # end
      #
      # r.on 'save_snippet' do
      #   response['Content-Type'] = 'application/json'
      #   FileUtils.mkpath(File.dirname(params[:snippet][:path]))
      #   File.open(File.join(ENV['ROOT'], params[:snippet][:path]), 'w') do |file|
      #     file.puts Base64.decode64(params[:snippet][:value])
      #   end
      #   { flash: { notice: "Saved file `#{params[:snippet][:path]}`" } }.to_json
      # end
      #
      # r.post do        # CREATE
      #   res = ScaffoldNewSchema.call(params[:scaffold] || {})
      #   errors = res.messages
      #   if errors.empty?
      #     result = GenerateNewScaffold.call(res.to_h)
      #     show_page { Development::Generators::Scaffolds::Show.call(result) }
      #   else
      #     puts errors.inspect
      #     show_page { Development::Generators::Scaffolds::New.call(params[:scaffold], errors) }
      #   end
      # end
    end
  end
end
