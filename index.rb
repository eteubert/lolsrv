require "bundler"
Bundler.require

require "pp"
require "uri"

class Commit
	include DataMapper::Resource

	property :id,       Serial
	property :sha,      String, :length => 64
	property :url,      Text
	property :message,  Text
	property :image_id, Text

	def file_url
		"/lol/#{sha}"
	end

	def has_image?
		true
	end
end

mongo_db = nil

def get_connection
  return @db_connection if @db_connection
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
  @db_connection
end

configure :development do
  DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
  mongo_db = Mongo::MongoClient.new('localhost', 27017).db('lolcommits')
end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
  mongo_db = get_connection
end

DataMapper.auto_upgrade!
mongo_grid = Mongo::Grid.new(mongo_db)
config = YAML.load(File.open('config.yaml'))

get '/' do
  @repo = config['github_repo']
	@commits = Commit.all.reverse
	erb :index
end

get '/lol/:sha' do |sha|
	content_type 'image/jpg'
	begin
		file = mongo_grid.get(BSON::ObjectId(Commit.first(sha: sha).image_id))
		response['Cache-Control'] = "public, max-age=60"
		file.read
	rescue Exception => e
	  pp e
		raise Sinatra::NotFound
	end
end

get '/lols' do
  commits = Commit.all
  commits.to_json(:only => [:sha])
end

post '/uplol' do
	Commit.create(
		sha:      params['sha'],
		image_id: mongo_grid.put(params['lol'][:tempfile])
	)
end