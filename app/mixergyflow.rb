require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'dm-core'
require 'dm-validations'
require 'fileutils'

require 'authorization'

helpers do
  include Sinatra::Authorization
end

def interview_class_helper(interviews, interview)
  class_string = interviews.last == interview ? 'last' : ''
  class_string = interviews.first == interview ? 'first' : ''
  class_string
end

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/mixergyflow.db")

class Interview
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :title, String
  property :url, Text
  property :created_at, DateTime
  
  validates_present :name
  validates_present :title
  validates_present :url
end

get '/' do
  redirect '/admin'
end

get '/admin' do
  require_administrative_privileges
  
  @interviews = Interview.all :order => [:created_at]
  
  haml :index, :format => :html5
end

post '/admin' do
  require_administrative_privileges
  
  Interview.create( :name => params[:name], 
    :title => params[:title],
    :url => params[:url],
    :created_at => Time.now 
  )
  
  FileUtils.mv(params[:data][:tempfile], File.join(File.dirname(__FILE__), '..', 'public', 'interviews'))
  
  redirect '/admin'
end

get '/admin/:id/delete' do
  Interview.get( params[:id] ).destroy
  
  redirect '/admin'
end

# SASS stylesheet
get '/stylesheets/mixergy_flow_admin.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :mixergy_flow_admin
end