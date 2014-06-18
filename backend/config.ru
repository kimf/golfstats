require 'rack/cors'
require './backend/golfstats_api'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :get
  end
end

run GolfstatsApi
