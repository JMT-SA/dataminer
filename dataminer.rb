require 'roda'
require 'rom'
require 'rom-sql'
require 'rom-repository'

require 'crossbeams/dataminer_interface'
require './lib/db_connections'

DB = DBConnections.new

class Dataminer < Roda
  plugin :render
  plugin :assets, css: 'style.scss'
  plugin :public
  plugin :content_for, append: true
  plugin :indifferent_params

  use Crossbeams::DataminerInterface::App, url_prefix: 'dataminer/',
                                           dm_reports_location: File.expand_path('../../../roda_frame/reports', __FILE__),
                                           dm_js_location: 'js',
                                           dm_css_location: 'css',
                                           db_connection: DB.base

  route do |r|
    r.assets unless ENV['RACK_ENV'] == 'production'
    r.public

    r.root do
      r.redirect '/dataminer/'
    end

    r.is 'versions' do
      s = '<h2>Gem Versions</h2><ul><li>'
      s << [Crossbeams::DataminerInterface,
            Crossbeams::Dataminer].map { |k| "#{k}: #{k.const_get('VERSION')}" }.join('</li><li>')
      s << '</li></ul>'
      view(inline: s)
    end
  end
end
