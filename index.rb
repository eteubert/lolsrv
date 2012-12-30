require "bundler"
Bundler.require

require "pp"
require "uri"

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
  mongo_db = Mongo::MongoClient.new('localhost', 27017).db('lolcommits')
end

configure :production do
  mongo_db = get_connection
end

mongo_grid = Mongo::Grid.new(mongo_db)
mongo_commits = mongo_db['commit']
config = YAML.load(File.open('config.yaml'))

get '/' do
	@repo = config['github_repo']

	mongo_commits.find().each { |commit|
		if !commit['date']
			begin
				puts "x"
				if github_commit = Octokit.commit(@repo, commit['sha'])
					date = DateTime.strptime(github_commit['commit']['author']['date']).to_time.to_i
					mongo_commits.update({"_id" => commit["_id"]}, {"$set" => { "date" => date }})
				end
			rescue Exception => e
				# pp e
				# raise
			end
		end
	}

	@commits = mongo_commits.find().sort({date: -1})
	erb :index
end

get '/lol/:sha' do |sha|
	content_type 'image/jpg'
	begin
		file = mongo_grid.get mongo_commits.find(sha: sha).first['image_id']
		response['Cache-Control'] = "public, max-age=60"
		file.read
	rescue Exception => e
	  pp e
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