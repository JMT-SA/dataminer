# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

class Dataminer < Roda
  route 'admin', 'dataminer' do |r|
    context = { for_grid_queries: session[:dm_admin_path] == :grids }
    interactor = DataminerInteractor.new(current_user, {}, context, {})

    # r.root do
    r.is do
      @page = interactor.admin_list
      view('dataminer/admin/index') # TODO: Change to framework view with grid.
      # renderer = Renderer::Grid.new('rpt_grid', '/dataminer/admin/grid/', 'Report listing')
      # view(inline: renderer.render)
    end

    r.on 'reports' do
      session[:dm_admin_path] = :reports
      r.redirect('/dataminer/admin')
    end

    r.on 'grids' do
      session[:dm_admin_path] = :grids
      r.redirect('/dataminer/admin')
    end

    r.on 'new' do
      @page = OpenStruct.new(filename: '',
                             caption: '',
                             sql: '')
      @err = ''
      view('dataminer/admin/new')
    end

    r.on 'create' do
      r.post do
        res = interactor.create_report(params)
        if res.success
          # TODO: table?
          view(inline: <<-HTML)
          <h1>Saved file...</h1>
          <p>Filename: <em>#{res.instance.filename}</em></p>
          <p>Caption: <em>#{res.instance.rpt.caption}</em></p>
          <p>SQL: <em>#{res.instance.rpt.runnable_sql}</em></p>
          <p>Columns:<br>#{res.instance.rpt.columns.map { |c| "<p>#{c}</p>" }.join}
          </p>
          HTML
        else
          @page = res.instance
          @err  = res.message
          view('dataminer/admin/new')
        end
      end
    end

    r.on 'convert' do
      r.post do
        unless params[:file] &&
               (@tmpfile = params[:file][:tempfile]) &&
               (@name = params[:file][:filename])
          r.redirect('/dataminer/admin/') # return "No file selected"
        end
        @yml  = @tmpfile.read # Store tmpfile so it's available for save? ... currently hiding yml in the form...
        @hash = YAML.load(@yml)
        view('dataminer/admin/convert')
      end
    end

    r.on 'save_conversion' do
      r.post do
        res = interactor.convert_report(params)
        # # puts ">>> PARAMS: #{params.inspect}"
        # # yml = nil
        # # File.open(params[:temp_path], 'r') {|f| yml = f.read }
        # yml = params[:yml]
        # hash = YAML.load(yml) ### --- could pass the params from the old yml & set them up too....
        # hash['query'] = params[:sql]
        # rpt = DmConverter.new(rep_loc).convert_hash(hash, params[:filename])
        # DmReportLister.new(rep_loc).get_report_list(persist: true) # Kludge to ensure list is rebuilt...
        #
        if res.success
          view(inline: <<-HTML)
          <h1>Converted</h1>
          <p>New YAML code:</p>
          <pre>#{yml_to_highlight(res.instance.to_hash.to_yaml)}</pre>
          HTML
        else
          view(inline: <<-HTML)
          <h1>Conversion failed</h1>
          <p>#{res.message}</p>
          HTML
        end
      end
    end

    r.on :id do |id|
      r.on 'edit' do
        @page = interactor.edit_report(id)
        view('dataminer/admin/edit')
      end

      r.on 'save' do
        r.post do
          res = interactor.save_report(id, params)
          if res.success
            flash[:notice] = "Report's header has been changed."
          else
            flash[:error] = res.message
          end
          r.redirect("/dataminer/admin/#{id}/edit/")
        end
      end
      r.on 'change_sql' do
        show_page { DM::Admin::ChangeSql.call(id) }
      end
      r.on 'save_new_sql' do
        r.patch do
          res = interactor.save_report_sql(id, params)
          if res.success
            flash[:notice] = "Report's SQL has been changed."
          else
            flash[:error] = res.message
          end
          r.redirect("/dataminer/admin/#{id}/edit/")
        end
      end
      r.on 'reorder_columns' do
        show_page { DM::Admin::ReorderColumns.call(id) }
      end
      r.on 'save_reordered_columns' do
        r.patch do
          res = interactor.save_report_column_order(id, params)
          if res.success
            flash[:notice] = "Report's column order has been changed."
          else
            flash[:error] = res.message
          end
          r.redirect("/dataminer/admin/#{id}/edit/")
        end
      end
      r.on 'save_param_grid_col' do # JSON
        res = interactor.save_param_grid_col(id, params)
        res.instance.to_json
      end
      r.on 'parameter' do
        r.on 'new' do
          # @rpt = ReportRepo.new.lookup_admin_report(id)
          # @cols = @rpt.ordered_columns.map(&:namespaced_name).compact
          # @tables = @rpt.tables
          # @id = id
          # view('dataminer/admin/new_parameter')
          show_page { DM::Admin::NewParameter.call(id) }
        end

        r.on 'create' do
          r.post do
            res = interactor.create_parameter(id, params)
            if res.success
              flash[:notice] = res.message
            else
              flash[:error] = res.message
            end
            r.redirect("/dataminer/admin/#{id}/edit/")
          end
        end
        r.on 'delete' do
          r.on :param_id do |param_id|
            res = interactor.delete_parameter(id, param_id)
            if res.success
              flash[:notice] = res.message
            else
              flash[:error] = res.message
            end
            r.redirect("/dataminer/admin/#{id}/edit/")
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
