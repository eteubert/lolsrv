require 'sinatra'
require 'data_mapper'
require 'octokit'

class Commit
	include DataMapper::Resource

	property :id,  Serial
	property :sha, String
	property :url, String
	property :message, String
end

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/development.rb")
DataMapper.auto_upgrade!


get '/' do
	erb :index
end