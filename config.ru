require './golfstats_api'

require 'rack'
require 'rack/contrib'
require 'rack/cors'
require 'rack-livereload'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end

use Rack::LiveReload

use Rack::ConditionalGet
use Rack::ETag

use Rack::Static, :urls => ['/index.html', '/js', '/css'], :root => 'public', :index =>
'index.html'

run GolfstatsApi
