require "sinatra"
configure do
  set :twitter_consumer_key, ""
  set :twitter_consumer_secret, ""
  set :cookie_secret, ""
end

require "./app"
run Sinatra::Application