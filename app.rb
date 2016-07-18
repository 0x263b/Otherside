#!/usr/bin/env ruby
# encoding: utf-8
require 'json'
require 'sinatra'
require 'oauth'
require 'omniauth-twitter'

configure do
  use Rack::Session::Cookie, 
    key: "rack.session",
    path: "/",
    expire_after: 14400,
    secret: settings.cookie_secret

  use OmniAuth::Builder do
    provider :twitter, settings.twitter_consumer_key, settings.twitter_consumer_secret
  end
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def prepare_access_token(oauth_token, oauth_token_secret)
    consumer = OAuth::Consumer.new(settings.twitter_consumer_key, settings.twitter_consumer_secret, {:site => "https://api.twitter.com", :scheme => :header })
    token_hash = { :oauth_token => oauth_token, :oauth_token_secret => oauth_token_secret }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash)

    return access_token
  end
end

get "/auth/twitter/callback" do
  session[:token] = request.env["omniauth.auth"]["credentials"]["token"]
  session[:secret] = request.env["omniauth.auth"]["credentials"]["secret"]

  redirect "/add"
end

get "/auth/failure" do
  @error = "<h3>Could not authenticate you with Twitter</h3>"
  @code = 1
  
  erb :index
end

get "/" do
  if !session[:token].nil? and !session[:secret].nil?
    redirect "/add"
  end

  @error = nil
  erb :index
end

get "/add" do
  @code = nil

  case params[:error_code]
  when "1"
    @error = "<h3>Could not authenticate you with Twitter</h3>"
    @code = 1
  when "2"
    @error = "<h3>Could not find that Twitter user</h3> <p>Please make sure you’ve typed their username correctly. Twitter usernames can only contain letters, numbers, and underscores.</p>"
  when "3"
    @error = "<h3>Could not retrieve followed accounts</h3> <p>Does this user have a private account?</p>"
  when "4"
    @error = "<h3>Could not create list</h3> <p>Twitter <a href='https://support.twitter.com/articles/15364'>imposes a limit</a> on <a href='https://support.twitter.com/articles/68916'>aggressive following</a>, and a follow limit of 1,000 a day. Please allow some time before trying again.</p>"
  when "5"
    @error = "<h3>Could not modify list</h3> <p>Twitter <a href='https://support.twitter.com/articles/15364'>imposes a limit</a> on <a href='https://support.twitter.com/articles/68916'>aggressive following</a>, and a follow limit of 1,000 a day. Please allow some time before trying again.</p>"
  else
    @error = nil
  end

  @access_token = session[:token]
  @secret = session[:secret]
  
  erb :add
end 

post "/create_list" do 
  begin
    screen_name = params[:screen_name]
    twitter_access_token = params[:access_token]
    twitter_access_token_secret = params[:secret]

    raise "1" if twitter_access_token.empty? or twitter_access_token_secret.empty?
    raise "2" if !!(screen_name =~ /[^\w]/)

    # Generate OAuth access token
    access_token = prepare_access_token(twitter_access_token, twitter_access_token_secret)
    
    # Get following list for `screen_name`
    req = access_token.request(:get, "https://api.twitter.com/1.1/friends/ids.json?cursor=-1&screen_name=#{screen_name}&count=5000")
    raise "3" if req.code != "200"

    response = JSON.parse(req.body, {:symbolize_names => true})
    ids = response[:ids]
    total = ids.length

    # Get our lists
    req = access_token.request(:get, "https://api.twitter.com/1.1/lists/list.json")
    response = JSON.parse(req.body, {:symbolize_names => true})

    # Check if we already have a list
    list = response.find{ |list| list[:slug] == screen_name }
    # Otherwise make one
    if list.nil?
      req = access_token.request(:post, "https://api.twitter.com/1.1/lists/create.json?name=#{screen_name}&mode=private&description=List%20generated%20by%20Otherside%20for%20Twitter%20https%3A%2F%2Fotherside.site")
      list = JSON.parse(req.body, {:symbolize_names => true})
    end
    
    list_id = list[:id_str]
    uri = list[:uri]

    raise "4" if list_id.nil?

    # Add our target to the list so we can see their replies
    req = access_token.request(:post, "https://api.twitter.com/1.1/lists/members/create.json?list_id=#{list_id}&screen_name=#{screen_name}")

    raise "5" if req.code != "200"

    # Iterate over the list of accounts
    complete = 0
    ids.each_slice(100) do |slice|
      complete += slice.length
      user_list = slice.join(",")

      access_token.request(:post, "https://api.twitter.com/1.1/lists/members/create_all.json?list_id=#{list_id}&user_id=#{user_list}")
    end

    redirect "https://twitter.com#{uri}"
  rescue Exception => @error
    redirect "/add?error_code=#{@error}"
  end
end
