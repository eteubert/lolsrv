require "bundler"
Bundler.require
require "sinatra"
require "sinatra/config_file"
require "pp"
require "uri"
require "yaml"
require "logger"
require 'fileutils'

class LolServer < Sinatra::Base
  helpers Sinatra::UrlForHelper
  register Sinatra::ConfigFile
  config_file 'config.yml'

  def self.get_connection
      return @db_connection if @db_connection
      db = URI.parse(ENV['MONGOHQ_URL'])
      db_name = db.path.gsub(/^\//, '')
      @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
      @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
      @db_connection
  end

  configure do
    $log = Logger.new('output.log','weekly')

    set :logging, false

    mongo_db = nil
    dirname = File.dirname('logs')
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    configure :development do
      mongo_db = Mongo::MongoClient.new('localhost', 27017).db('lolcommits')
      ENV['CLIENT_ID'] = settings.CLIENT_ID
      ENV['CLIENT_SECRET'] = settings.CLIENT_SECRET
      $log.level = Logger::DEBUG
    end

    configure :production do
      mongo_db = self::get_connection
      $log.level = Logger::WARN
    end

    set :mongo_grid => Mongo::Grid.new(mongo_db)
    set :mongo_commits => mongo_db['commit']
  end

  get '/' do
    client = Octokit::Client.new \
        :client_id => ENV['CLIENT_ID'],
        :client_secret => ENV['CLIENT_SECRET']

    settings.mongo_commits.find({ 'date' => {'$exists' => false} }).each { |commit|
		begin
        #This is great and all, but it needs to be authenticated to use
        github_commit = Octokit.commit(commit['repo'], commit['sha'])
        if github_commit
          p 'Found Commit'
          @repo = commit['repo']
          date = DateTime.strptime(github_commit['commit']['author']['date']).to_time.to_i
          settings.mongo_commits.update({"_id" => commit["_id"]}, {"$set" => { "date" => date }})
        else
          settings.mongo_commits.update({"_id" => commit["_id"]}, {"$set" => { "date" => commit["time"] }})
        end
      rescue Exception => e
			pp e
			#raise
		end
	}
	@commits = settings.mongo_commits.find().sort({time: -1, date: -1})
	erb :index
  end

  get '/lol/:sha' do |sha|
	content_type 'image/jpg'
	begin
		file = settings.mongo_grid.get settings.mongo_commits.find(sha: sha).first['image_id']
		response['Cache-Control'] = "public, max-age=60"
		file.read
	rescue Exception => e
	  pp e
		raise Sinatra::NotFound
	end
  end

  get '/lols' do
    commits = settings.mongo_commits.find().sort({date: -1})
    commits.to_a.map { |c| {sha: c['sha']} }.to_json
  end

  post '/uplol' do
	settings.mongo_commits.insert(
		sha:      params['sha'],
        url:      params['url'],
        time:     params['date'],
        repo:     params['repo'],
		image_id: settings.mongo_grid.put(params['lol'][:tempfile])
	)
  end
end
