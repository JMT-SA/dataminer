# JS VM instance on VirtualBox
server '10.0.0.7', user: 'nsld', roles: %w[app db web]
set :deploy_to, '/home/nsld/dataminer'
