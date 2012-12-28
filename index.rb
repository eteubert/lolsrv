require 'sinatra'
require 'data_mapper'
require 'octokit'
require 'pp'
require 'mongo'
require 'bson'

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

DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/development.db")
DataMapper.auto_upgrade!

mongo_db   = Mongo::MongoClient.new('localhost', 27017).db('lolcommits')
mongo_grid = Mongo::Grid.new(mongo_db)

get '/' do
	@commits = Commit.all
	erb :index
end

get '/lol/:sha' do |sha|
	content_type 'image/jpg'
	begin
		file = mongo_grid.get(BSON::ObjectId(Commit.first(sha: sha).image_id))
		response['Cache-Control'] = "public, max-age=60"
		file.read
	rescue Exception => e
		raise Sinatra::NotFound
	end
end

post '/uplol' do
	Commit.create(
		sha:      params['sha'],
		image_id: mongo_grid.put(params['lol'][:tempfile])
	)
end