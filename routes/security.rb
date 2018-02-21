# frozen_string_literal: true

Dir['./routes/security/*.rb'].each { |f| require f }

class Dataminer < Roda
  route('security') do |r|
    r.multi_route('security')
  end
end
