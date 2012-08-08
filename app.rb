require 'sinatra'
require "sinatra/reloader" if development?
require 'oauth2'
require 'json'

enable :sessions

@@client_id = "YOUR CLIENT ID HERE"
@@client_secret = "YOUR CLIENT SECRET HERE"

# OAUTH2
def client
  OAuth2::Client.new(@@client_id, @@client_secret, :site => "http://localhost:3000")
end

get "/signin" do
  redirect client.auth_code.authorize_url(:redirect_uri => redirect_uri)
end

get "/signout" do
  session.clear
  redirect "/"
end

get '/auth/callback' do  
  access_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
  session[:access_token] = access_token.token
  @message = "Successfully authenticated with the server"
  erb access_token.token
end

get '/client_credentials' do
  access_token = client.client_credentials.get_token
  session[:access_token] = access_token.token
  @message = "Successfully authenticated with the server"
  erb access_token.token
end

get '/token' do
  session[:access_token]
end
get '/user' do
  access_token = OAuth2::AccessToken.new(client, session[:access_token])
  JSON.parse(access_token.get("/oauth/user").body)
end
get '/wares' do
  @wares = get_response('wares.json')
  @wares.inspect
end
get '/providers' do
  @providers = get_response('providers.json')
  @providers.inspect
end

get '/' do
  haml File.open("views/index.html.haml").read
end

def get_response(url)
  access_token = OAuth2::AccessToken.new(client, session[:access_token])
  JSON.parse(access_token.get("/api/#{url}").body)
end


def redirect_uri
  uri = URI.parse(request.url)
  uri.path = '/auth/callback'
  uri.query = nil
  uri.to_s
end

