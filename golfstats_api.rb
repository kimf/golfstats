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

    def clubs_json(clubs)
      clubs_array = []
      clubs.each do |c|
        clubs_array << {
          id: c.id,
          name: c.name,
          lat: c.lat,
          lng: c.lng,
          updated_at: c.updated_at,
          courses: courses_json(c.courses)
        }
      end
      clubs_array
    end

    def courses_json(courses)
      courses_array = []
      courses.each do |course|
        courses_array << {
          id: course.id,
          name: course.name,
          holes_count: course.holes_count,
          par: course.par,
          updated_at: course.updated_at,
          club_id: course.club_id,
          slopes: slopes_json(course.slopes)
        }
      end
      courses_array
    end

    def holes_json(holes)
      holes_array = []
      holes.each do |hole|
        holes_array << {
          id: hole.id,
          course_id: hole.course_id,
          number: hole.number,
          index: hole.index,
          par: hole.par,
          hole_pos: hole.hole_pos,
          tee_pos: hole.tee_pos
        }
      end
      holes_array
    end

    def slopes_json(slopes)
      slopes_array = []
      slopes.each do |slope|
        slopes_array << {
          id: slope.id,
          course_id: slope.course_id,
          course_rating: slope.course_rating,
          slope_value: slope.slope_value,
          name: slope.name,
          length: slope.length
        }
      end
      slopes_array
    end

    def slope_json(slope)
      {
        id: slope.id,
        course_id: slope.course_id,
        course_rating: slope.course_rating,
        slope_value: slope.slope_value,
        name: slope.name,
        length: slope.length
      }
    end

    # def authenticate!
    #   error!('401 Unauthorized', 401) unless current_user
    # end
  end

  desc "Return scorecards updated after given date"
  get "/scorecards" do
    cache.clear
    year = params[:year].nil? ? "All" : params[:year]
    year_string = year == "All" ?  ""  : "AND EXTRACT(year FROM date) = #{year}"
    fields = 'id, date, course, par, strokes_out, strokes_in, strokes, points, putts, putts_avg, putts_out, putts_in, '\
             'girs, firs, strokes_over_par, scores_count, not_par_three_holes, distance, consistency, scores, '\
             'created_at, updated_at, scoring_distribution, putts_gir_avg'

    query = <<-SQL
      SELECT #{fields} FROM scorecards WHERE scores_count = 18 #{year_string} ORDER BY date ASC
    SQL

    @scorecards = cache.get("scorecards_#{year}_json") || nil
    if @scorecards.nil?
      @scorecards = {scorecards: Scorecard.find_by_sql(query)} # .to_json
      cache.set("scorecards_#{year}_json", @scorecards)
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

  desc "Returns a list of all the clubs"
  get "/clubs" do
    clubs = cache.get("clubs_json") || nil

    if clubs.nil?
      clubs = {clubs: clubs_json(Club.includes(courses: [:slopes]).all)}
      cache.set("clubs_json", clubs)
    end

    header 'Cache-Control', 'public, max-age=31536000'
    header 'Expires', (Date.today + 1.year).httpdate
    clubs
  end

  desc "Returns holes for one course"
  get "/courses/:id/holes" do
    id = params[:id]

    json = cache.get("course_holes_json_#{id}") || nil
    if json.nil?
      json = holes_json(Course.includes(:holes).find(params[:id]).holes)
      cache.set("course_holes_json_#{id}", json)
    end

    header 'Cache-Control', 'public, max-age=31536000'
    header 'Expires', (Date.today + 1.year).httpdate
    json
  end

  desc 'Update a holes gps positions'
  params do
    requires :id, type: Integer
    requires :teePos, type: Array[Float]
    requires :holePos, type: Array[Float]
  end
  post '/holes/:id/position' do
    hole = Hole.find(params[:id])
    hole.tee_pos = params[:teePos]
    hole.hole_pos = params[:holePos]
    hole.save
    hole
  end
end
