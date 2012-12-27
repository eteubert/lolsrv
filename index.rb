require 'sinatra'
require 'data_mapper'
require 'octokit'
require 'pp'

class Commit
	include DataMapper::Resource

	property :id,      Serial
	property :sha,     String, :length => 64
	property :url,     Text
	property :message, Text

	def file_url
		"img/commits/#{sha[0...11]}.jpg"
	end

	def has_image?
		File.exist?("public/#{file_url}")
	end
end

DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/development.db")
DataMapper.auto_upgrade!

get '/' do
	@commits = Commit.all
	erb :index
end

get '/fetch' do
	commits = Octokit.commits "eteubert/podlove"
	commits.each do |commit|
		sha = commit.sha

		if sha && !Commit.all(:sha => sha).count
			Commit.create(
				sha: commit.sha,
				url: commit.url,
				message: commit.commit.message
			)
		end

	end

	"fetching complete"
end