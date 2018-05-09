# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

class Dataminer < Roda
  route 'masterfiles', 'development' do |r|

    # USERS
    # --------------------------------------------------------------------------
    r.on 'users', Integer do |id|
      interactor = DevelopmentApp::UserInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:users, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        raise Crossbeams::AuthorizationError unless authorised?('masterfiles', 'edit')
        show_partial { Development::Masterfiles::User::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          raise Crossbeams::AuthorizationError unless authorised?('masterfiles', 'read')
          show_partial { Development::Masterfiles::User::Show.call(id) }
        end
        r.patch do     # UPDATE
          return_json_response
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
          return_json_response
          raise Crossbeams::AuthorizationError unless authorised?('masterfiles', 'delete')
          res = interactor.delete_user(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'users' do
      interactor = DevelopmentApp::UserInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        raise Crossbeams::AuthorizationError unless authorised?('masterfiles', 'new')
        show_partial_or_page(r) { Development::Masterfiles::User::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_user(params[:user])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/development/masterfiles/users/new') do
            Development::Masterfiles::User::New.call(form_values: params[:user],
                                                     form_errors: res.errors,
                                                     remote: fetch?(r))
          end
        end
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
