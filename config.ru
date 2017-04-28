require './dataminer.rb'
use Rack::Session::Cookie, secret: "some_nice_long_random_string_DSKJH4378EYR7EGKUFH", key: "_dm_session"

run Dataminer
