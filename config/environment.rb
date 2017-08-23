require 'dotenv'

Dotenv.load

require 'sequel'
DB = Sequel.connect(ENV.fetch('DM_DATABASE_URL'))
