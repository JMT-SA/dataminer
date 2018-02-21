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
  end
end
