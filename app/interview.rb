class Interview
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :title, String
  property :url, Text
  property :picture_name, String
  property :created_at, DateTime
  
  validates_present :name
  validates_present :title
  validates_present :url
  validates_present :picture_name
end

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/mixergyflow.db")