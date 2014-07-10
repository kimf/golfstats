$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), 'models')
require 'rubygems'
require 'yaml'
require 'bundler/setup'
Bundler.require(:default)

Dir["backend/models/*.rb"].each do |file|
 require "./#{file}"
end

#require 'debugger' if ENV['RACK_ENV'] == "development"

@environment = ENV['RACK_ENV'] || 'development'
@dbconfig = YAML.load(File.read('backend/database.yml'))
ActiveRecord::Base.establish_connection @dbconfig[@environment]
ActiveRecord::Base.logger = Logger.new(STDOUT)
#, :username => "youruser", :password => "yourpassword"  )


# #old formatter, for now! see: http://code.dblock.org/grape-040-released-w-stricter-json-format-support-more
# module Grape
#   module Formatter
#     module Json
#       class << self
#         def call(object, env)
#           return object if ! object || object.is_a?(String)
#           return object.to_json if object.respond_to?(:to_json)
#           raise Grape::Exceptions::InvalidFormatter.new(object.class, 'json')
#         end
#       end
#     end
#   end
# end

class Cache
  def initialize
    @client = Dalli::Client.new
  end

  def clear
    @client.flush_all
  end

  def get(key)
    @client.get(key)
  end

  def set(key, value)
    @client.set(key, value)
  end
end

class GolfstatsApi < Grape::API

  format :json
  default_format :json
  content_type :json, "application/json; charset=utf-8"

  attr_accessor :db

  helpers do
    # def current_user
    #   @current_user ||= User.authorize!(env)
    # end

    def cache
      Cache.new
    end

    # def authenticate!
    #   error!('401 Unauthorized', 401) unless current_user
    # end
  end


  desc "Return scorecards updated after given date"
  get "/scorecards" do
    year = params[:year].nil? ? "2014" : params[:year]
    year_string = params[:year] == "All" ?  ""  : "AND EXTRACT(year FROM date) = #{year}"

    query = <<-SQL
      SELECT * FROM scorecards WHERE scores_count = 18 #{year_string}
    SQL

    @scorecards = cache.get("scorecards_#{year}_json") || nil
    if @scorecards.nil?
      @scorecards = {scorecards: Scorecard.find_by_sql(query)} #.to_json
      cache.set("scorecards_#{year}_json", @scorecards)
    end

    header 'Cache-Control', 'public, max-age=31536000'
    header 'Expires', (Date.today + 1.year).httpdate
    @scorecards
  end

  desc "Returns scores for given ids"
  get "/scores" do
    ids = params[:ids]

    query = <<-SQL
      SELECT * FROM scores WHERE id IN(#{ids})
    SQL

    @scores = cache.get("scorecards_#{ids.join('_')}_json") || nil
    if @scores.nil?
      @scores = {scores: Score.find_by_sql(query)} #.to_json
      cache.set("scorecards_#{ids.join('_')}_json", @scores)
    end

    header 'Cache-Control', 'public, max-age=31536000'
    header 'Expires', (Date.today + 1.year).httpdate
    @scores
  end
end
