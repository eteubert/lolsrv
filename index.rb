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
		# "img/commits/#{sha[0...11]}.jpg"
		"/lol/#{sha}"
	end

	def has_image?
		true
		# File.exist?("public/#{file_url}")
	end
end

DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/development.db")
DataMapper.auto_upgrade!

include Mongo

mongo_connection = MongoClient.new('localhost', 27017)
mongo_db         = mongo_connection['lolcommits']
mongo_grid       = Mongo::Grid.new(mongo_db)

get '/' do
	@commits = Commit.all
	erb :index
end

get '/fetch' do
	Commit.all.destroy
	commits = Octokit.commits "eteubert/podlove"
	commits.each do |commit|
		sha = commit.sha

		# if sha && !Commit.all(:sha => sha).count
			Commit.create(
				sha: commit.sha,
				url: commit.url,
				message: commit.commit.message
			)
		# end

	end

	"fetching complete"
end

get '/lol/:sha' do |sha|
	
	if commit = Commit.first(sha: sha)
		response['Cache-Control'] = "public, max-age=60"
		file = mongo_grid.get(commit.image_id)
		file.read
	else
		raise Sinatra::NotFound
	end

end

post '/uplol' do
  # File.open(params['lol'][:filename], "w") do |f|
  	
  	image_id = mongo_grid.put(params['lol'][:tempfile])

  	Commit.create(
  		sha:      params['sha'],
  		image_id: image_id
  	)

    # return "File " + params['lol'][:filename] + " (" + params['lol'][:tempfile].size.to_s + " Bytes) uploaded!"
  # end
end