$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), 'models')
require 'rubygems'
require 'yaml'
require 'bundler/setup'
Bundler.require(:default)

Dir["models/*.rb"].each do |file|
 require "./#{file}"
end

@environment = ENV['RACK_ENV'] || 'development'
@dbconfig = YAML.load(File.read('database.yml'))
ActiveRecord::Base.establish_connection @dbconfig[@environment]
ActiveRecord::Base.logger = Logger.new(STDOUT)
#, :username => "youruser", :password => "yourpassword"  )


require 'byebug' if @environment == "development"

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
    year = params[:year].nil? ? "All" : params[:year]
    year_string = params[:year] == "All" ?  ""  : "AND EXTRACT(year FROM date) = #{year}"
    user_id = params[:user_id].nil? ? 1 : params[:user_id]

    query = <<-SQL
      SELECT * FROM scorecards WHERE user_id = #{user_id} AND scores_count = 18 #{year_string} ORDER BY date ASC
    SQL

    @scorecards = cache.get("scorecards_#{year}_#{user_id}_json") || nil
    if @scorecards.nil?
      @scorecards = {scorecards: Scorecard.find_by_sql(query)} #.to_json
      cache.set("scorecards_#{year}_#{user_id}_json", @scorecards)
    end

    if @environment != "development"
      header 'Cache-Control', 'public, max-age=31536000'
      header 'Expires', (Date.today + 1.year).httpdate
    end
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

    if @environment != "development"
      header 'Cache-Control', 'public, max-age=31536000'
      header 'Expires', (Date.today + 1.year).httpdate
    end
    @scores
  end
end
