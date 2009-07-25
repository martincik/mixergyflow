require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'dm-core'
require 'dm-validations'
require 'nokogiri'
require 'fileutils'
require 'authorization'
require 'interview'

use Rack::Session::Cookie
 
helpers do
  include Sinatra::Authorization
  
  def flash
    @_flash ||= {}
  end
  
  def redirect(uri, *args)
    session[:_flash] = flash unless flash.empty?
    status 302
    response['Location'] = uri
    halt(*args)
  end
end
 
before do
  @_flash, session[:_flash] = session[:_flash], nil if session[:_flash]
end

INTERVIEW_OUTPUT_PATH = File.join(File.dirname(__FILE__), '..', 'public')
INTERVIEW_PICTURE_PATH = File.join(INTERVIEW_OUTPUT_PATH, 'interviews')

def interview_class_helper(interviews, interview)
  if interviews.last == interview
    'last'
  else 
    (interviews.first == interview ? 'first' : '')
  end
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
  
  picture_name = params[:data] ? params[:data][:filename] : nil
  
  @interview = Interview.new( :name => params[:name], 
    :title => params[:title],
    :url => params[:url],
    :picture_name => picture_name,
    :created_at => Time.now 
  )
  
  if @interview.save
    flash[:notice] = "Interview added successfully. Well done! &#xF8FF;"
  else
    flash[:error] = "Failed to add interview! &#x262F; &ndash; Did you fill them all?"
  end
  
  if picture_name
    dest_file = File.join(INTERVIEW_PICTURE_PATH, params[:data][:filename])
    File.open(dest_file,"wb+") do |f| 
      f.write(params[:data][:tempfile].read) 
    end
  end
  
  redirect '/admin'
end

get '/admin/:id/delete' do
  require_administrative_privileges
  
  interview = Interview.get params[:id]
  
  # Instead of calling dangerous 'rm' method it's safer to move files to "trash"
  FileUtils.mv(File.join(INTERVIEW_PICTURE_PATH, interview.picture_name), 
    File.join('/tmp', interview.picture_name), :force => true)
  
  if interview.destroy
    flash[:notice] = "Interview deleted successfully."
  else
    flash[:error] = "Failed to delete interview&iexcl; Probably time to call 911..."
  end
  
  redirect '/admin'
end

get '/admin/regenerate' do
  require_administrative_privileges
  
  @interviews = Interview.all :order => [:created_at]
  
  interview_haml_template = File.read(File.join(File.dirname(__FILE__), 'views', '_interviews.haml'))

  dest_file = File.join(INTERVIEW_OUTPUT_PATH, 'index.html')
  
  markup = Nokogiri::HTML.parse(File.read(dest_file))
  markup.search("#MooFlow").each do |el|
    engine = Haml::Engine.new(interview_haml_template, :attr_wrapper => '"')
    el.inner_html = engine.render(Object.new, :interviews => @interviews)
  end
  
  File.open(dest_file,"wb+") do |f| 
    f.write(markup.to_html) 
  end
  
  redirect '/admin'
end

# SASS stylesheet
get '/stylesheets/mixergy_flow_admin.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :mixergy_flow_admin
end