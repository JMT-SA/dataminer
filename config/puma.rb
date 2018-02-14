environment 'production'
root_dir = File.expand_path('../../', __FILE__)
bind "unix://#{root_dir}/tmp/sockets/label-designer-puma.sock"
directory root_dir
# pidfile '/home/nsld/label_designer/tmp/puma/pid'
# state_path 'home/nsld/label_designer/tmp/puma/state'
stdout_redirect "#{root_dir}/log/stdout", "#{root_dir}/log/stderr", true
# activate_control_app
