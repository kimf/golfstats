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

    def slopes_json(slopes)
      slopes_array = []
      slopes.each do |slope|
        slopes_array << {
          id: slope.id,
          course_id: slope.course_id,
          course_rating: slope.course_rating,
          slope_value: slope.slope_value,
          name: slope.name,
          length: slope.length,
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
        length: slope.length,
        tees: tees_json(slope.tees)
      }
    end

    def tees_json(tees)
      tees_array = []
      tees.each do |t|
        tees_array << {
          id: t.id,
          length: t.length,
          lat: t.lat,
          lng: t.lng,
          hole: t.hole,
          slope_id: t.slope_id
        }
      end
      tees_array
    end

    # def authenticate!
    #   error!('401 Unauthorized', 401) unless current_user
    # end
  end

  desc "Return scorecards updated after given date"
  get "/scorecards" do
    year = params[:year].nil? ? "All" : params[:year]
    year_string = year == "All" ?  ""  : "AND EXTRACT(year FROM date) = #{year}"
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

  desc "Returns a list of all the courses for a club"
  get "/clubs/:id/courses" do
    id = params[:id]
    courses = cache.get("courses_json_club_#{id}") || nil
    if courses.nil?
      courses = {courses: Course.includes(:club).where(club_id: id).all}
      cache.set("courses_json_club_#{id}", courses)
    end

    header 'Cache-Control', 'public, max-age=31536000'
    header 'Expires', (Date.today + 1.year).httpdate
    courses
  end

  desc "Returns data for one course"
  get "/courses/:id" do
    id = params[:id]

    json = cache.get("courses_json_#{id}") || nil
    if json.nil?
      course = Course.includes(:slopes).find(params[:id])
      json = {
        id: course.id,
        name: course.name,
        holes_count: course.holes_count,
        par: course.par,
        created_at: course.created_at,
        updated_at: course.updated_at,
        club: course.club,
        slopes: course.slopes
      }
      cache.set("courses_json_#{id}", json)
    end

    header 'Cache-Control', 'public, max-age=31536000'
    header 'Expires', (Date.today + 1.year).httpdate
    json
  end

  desc "Returns data for one slope"
  get "/slopes/:id" do
    id = params[:id]

    json = cache.get("slopes_json_#{id}") || nil
    if json.nil?
      slope = Slope.includes(:course, tees:[:hole]).find(params[:id])
      json = slope_json(slope)
      cache.set("slopes_json_#{id}", json)
    end

    header 'Cache-Control', 'public, max-age=31536000'
    header 'Expires', (Date.today + 1.year).httpdate
    json
  end

end
