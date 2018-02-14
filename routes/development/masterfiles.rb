# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

class Dataminer < Roda
  route 'masterfiles', 'development' do |r|
    # USERS
    # --------------------------------------------------------------------------
    r.on 'users', Integer do |id|
      interactor = UserInteractor.new(current_user, {}, {}, {})

      # Check for notfound:
      r.on !interactor.exists?(:users, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        if authorised?('masterfiles', 'edit')
          show_partial { Development::Masterfiles::User::Edit.call(id) }
        else
          dialog_permission_error
        end
      end
      r.is do
        r.get do       # SHOW
          if authorised?('masterfiles', 'read')
            show_partial { Development::Masterfiles::User::Show.call(id) }
          else
            dialog_permission_error
          end
        end
        r.patch do     # UPDATE
          response['Content-Type'] = 'application/json'
          res = interactor.update_user(id, params[:user])
          if res.success
            update_grid_row(id,
                            changes: { login_name: res.instance[:login_name],
                                       user_name: res.instance[:user_name],
                                       password_hash: res.instance[:password_hash],
                                       email: res.instance[:email],
                                       active: res.instance[:active] },
                            notice: res.message)
          else
            content = show_partial { Development::Masterfiles::User::Edit.call(id, params[:user], res.errors) }
            update_dialog_content(content: content, error: res.message)
          end
        end
        r.delete do    # DELETE
          response['Content-Type'] = 'application/json'
          res = interactor.delete_user(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'users' do
      interactor = UserInteractor.new(current_user, {}, {}, {})
      r.on 'new' do    # NEW
        if authorised?('masterfiles', 'new')
          show_partial_or_page(fetch?(r)) { Development::Masterfiles::User::New.call(remote: fetch?(r)) }
        else
          fetch?(r) ? dialog_permission_error : show_unauthorised
        end
      end
      r.post do        # CREATE
        res = interactor.create_user(params[:user])
        if res.success
          flash[:notice] = res.message
          if fetch?(r)
            redirect_via_json_to_last_grid
          else
            redirect_to_last_grid(r)
          end
        elsif fetch?(r)
          content = show_partial do
            Development::Masterfiles::User::New.call(form_values: params[:user],
                                                     form_errors: res.errors,
                                                     remote: true)
          end
          update_dialog_content(content: content, error: res.message)
        else
          flash[:error] = res.message
          show_page do
            Development::Masterfiles::User::New.call(form_values: params[:security_group],
                                                     form_errors: res.errors,
                                                     remote: false)
          end
        end
      end
    end
  end
end
