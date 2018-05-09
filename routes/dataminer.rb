# frozen_string_literal: true

Dir['./routes/dataminer/*.rb'].each { |f| require f }

class Dataminer < Roda
  route('dataminer') do |r|
    store_current_functional_area('dataminer')
    r.multi_route('dataminer')
  end
end
