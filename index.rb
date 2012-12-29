require 'sinatra'
require 'octokit'
require 'pp'
require 'mongo'
require 'json'
require 'bson'
require 'sinatra/url_for'

mongo_client  = Mongo::MongoClient.new('localhost', 27017)
mongo_db      = mongo_client['lolcommits']
mongo_grid    = Mongo::Grid.new(mongo_db)
mongo_commits = mongo_db['commit']

get '/' do
	@commits = mongo_commits.find()
	erb :index
end

get '/lol/:sha' do |sha|
	content_type 'image/jpg'
	begin
		file = mongo_grid.get mongo_commits.find(sha: sha).first['image_id']
		response['Cache-Control'] = "public, max-age=60"
		file.read
	rescue Exception => e
		raise Sinatra::NotFound
	end
end

get '/lols' do
  commits = mongo_commits.find()
  commits.to_a.map { |c| {sha: c['sha']} }.to_json
end

post '/uplol' do
	mongo_commits.insert(
		sha:      params['sha'],
		image_id: mongo_grid.put(params['lol'][:tempfile])
	)
end