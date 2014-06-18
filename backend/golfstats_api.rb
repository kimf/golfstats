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


#old formatter, for now! see: http://code.dblock.org/grape-040-released-w-stricter-json-format-support-more
module Grape
  module Formatter
    module Json
      class << self
        def call(object, env)
          return object if ! object || object.is_a?(String)
          return object.to_json if object.respond_to?(:to_json)
          raise Grape::Exceptions::InvalidFormatter.new(object.class, 'json')
        end
      end
    end
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

    # def authenticate!
    #   error!('401 Unauthorized', 401) unless current_user
    # end
  end


  desc "Return scorecards updated after given date"
  get "/scorecards" do
    #authenticate!
    #current_user.scorecards
    after_date = params[:after_date].nil? ? "2014-01-01" : params[:after_date]

    query = <<-SQL
     SELECT * FROM scorecards WHERE scores_count = 18
    SQL

    @scorecards = {scorecards: Scorecard.find_by_sql(query)}.to_json
    # Scorecard.after_date(after_date).all_json(
    #                 columns: [
    #                           :id, :date, :par, :strokes_out, :strokes_in, :strokes, :putts, :putts_avg, :putts_out, :putts_in, :girs, :firs, :strokes_over_par,
    #                           :scores_count, :not_par_three_holes, :distance, :consistency, :scores, :updated_at]
    #             )
  end

  desc "Returns scores for given ids"
  get "/scores" do
    ids = params[:ids]
    query = <<-SQL
      SELECT * FROM scores WHERE id IN(#{ids})
    SQL

    @scores = {scores: Score.find_by_sql(query)}.to_json
  end

  # desc "Create a scorecard and scores"
  # post "/scorecards" do
  #   new_params = params[:scorecard].to_hash
  #   scores = new_params.delete("scores")
  #   Scorecard.transaction do
  #     scorecard =  Scorecard.create(new_params)
  #     scores.each do |s|
  #       s[:scorecard] = scorecard
  #       Score.create(s)
  #     end
  #     {succes: true, message: "Scorecard was synced!"}.to_json
  #   end
  # end

end
