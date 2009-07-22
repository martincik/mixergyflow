require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'dm-core'
require 'dm-validations'
require 'fileutils'
require 'authorization'
require 'interview'

helpers do
  include Sinatra::Authorization
end

INTERVIEW_PICTURE_PATH = File.join(File.dirname(__FILE__), '..', 'public', 'interviews')

def interview_class_helper(interviews, interview)
  if interviews.last == interview
    'last' 
  else 
    (interviews.first == interview ? 'first' : '')
  end
end

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/mixergyflow.db")

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
    :picture_name => params[:data][:filename],
    :created_at => Time.now 
  )
  
  dest_file = File.join(INTERVIEW_PICTURE_PATH, params[:data][:filename])
  File.open(dest_file,"wb+") do |f| 
    f.write(params[:data][:tempfile].read) 
  end
  
  redirect '/admin'
end

get '/admin/:id/delete' do
  interview = Interview.get( params[:id] )
  
  # Instead of calling dangerous 'rm' method it's safer to move files to "trash"
  FileUtils.mv(File.join(INTERVIEW_PICTURE_PATH, interview.picture_name), 
    File.join('/tmp', interview.picture_name))
  
  interview.destroy
  
  redirect '/admin'
end

# SASS stylesheet
get '/stylesheets/mixergy_flow_admin.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :mixergy_flow_admin
end