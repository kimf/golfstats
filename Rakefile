$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), 'models')
require 'yaml'
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'open-uri'

require 'byebug'

#KIM
USER_ID=1
GOLFSHOT_URL="http://golfshot.com/members/0192098630/rounds"
#BOLLE
# USER_ID=2
# GOLFSHOT_URL="http://golfshot.com/members/0143076350/rounds"


Dir["./models/*.rb"].each do |file|
 require "./#{file}"
end

@environment = ENV['RACK_ENV'] || 'development'

@dbconfig = YAML.load(File.read('database.yml'))
ActiveRecord::Base.establish_connection @dbconfig[@environment]
ActiveRecord::Base.logger = Logger.new(STDOUT)




namespace :db do

  desc "do migrations"
  task :migrate do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate "db/migrate", ENV['VERSION'] ? ENV['VERSION'].to_i : nil
  end

  desc "drop db"
  task :drop do
    puts "dropping #{@dbconfig[@environment]["database"]}"
    %x( dropdb #{@dbconfig[@environment]["database"]} )
  end

  desc "create db"
  task :create do
    puts "creating #{@dbconfig[@environment]["database"]}"
    %x( createdb -E UTF8 -T template0 #{@dbconfig[@environment]["database"]} )
  end

  desc "Import courses from json files in _data"
  task :courses do
    Dir["_data/courses/*.json"].each do |file|
      club = JSON.parse(File.read(file))

      next if club["Data"]["Courses"].nil?

      lat = club["MapLat"]
      lng = club["MapLng"]

      club_name = club["Name"]

      club["Data"]["Courses"].each do |c|
        name        = c["Name"]
        holes_count = c["NumberOfHoles"]
        par         = c["Par"]

        course = Course.create(club: club_name, name: name, holes_count: holes_count, par: par, lat: lat, lng: lng)

        slopes = []
        c["Loop"]["Slopes"].each do |s|
          next if s["Gender"] == 0

          course_rating = s["CourseRating"]
          slope_value   = s["SlopeValue"]
          male          = s["Gender"] == 1
          name          = s["TeeColor"]

          slopes << Slope.create(course: course, course_rating: course_rating, slope_value: slope_value, male: male, name: name)
        end

        c["Loop"]["Holes"].each do |h|
          number            = h["Number"]
          par               = h["Par"]
          index             = h["Index"]
          green_center_lat  = h["GreenCenterLatitude"]
          green_center_lng  = h["GreenCenterLongitude"]
          green_front_lat   = h["GreenFrontLatitude"]
          green_front_lng   = h["GreenFrontLongitude"]
          green_depth       = h["GrenDepth"]

          hole = Hole.create(course: course, number: number, par: par, index: index, green_center_lat: green_center_lat, green_center_lng: green_center_lng, green_front_lat: green_front_lat, green_front_lng: green_front_lng, green_depth: green_depth)


          h["Tees"].each do |t|
            slope   = slopes.select{|s| s.name == t["Color"]}.first
            length  = t["Length"]
            lat     = t["TeeLatitude"]
            lng     = t["TeeLongitude"]

            tee = Tee.create(hole: hole, slope: slope, length: length, lat: lat, lng: lng)
          end
        end

        slopes.each{|s| s.update_attribute(:length, s.tees.map(&:length).sum) }
      end
    end
  end


  desc "Imports scorecards from golfshot.com"
  task :import do
    ActiveRecord::Base.logger = nil

    NAMES = ActiveSupport::OrderedHash.new
    NAMES[-2] = 'eagle'
    NAMES[-1] = 'birdie'
    NAMES[0] = 'par'
    NAMES[1] = 'bogey'
    NAMES[2] = 'double'
    NAMES[3] = 'triple'
    NAMES[4] = 'quadruple'
    NAMES.freeze


    class Cache
      def initialize
        @client = Dalli::Client.new
      end

      def clear
        @client.flush_all
      end

      def get(request)
        @client.get(request.cache_key)
      end

      def set(request, response)
        @client.set(request.cache_key, response)
      end
    end
    #Cache.new.clear #sometimes, stuff works in mysterious ways

    Typhoeus::Config.cache = Cache.new
    Typhoeus::Config.memoize = true

    hydra = Typhoeus::Hydra.new(:max_concurrency => 1000)
    puts "- STARTING ---------------------------------------------------------------"

    scorecards = []

    #First request does not need to be hydra
    doc = Nokogiri::HTML(open(GOLFSHOT_URL))

    pages = doc.css("div#roundList .pagination ul a")
    pages.reverse.each do |page|

      page_request = Typhoeus::Request.new("http://golfshot.com#{page["href"]}", followlocation: true)

      page_request.on_complete do |response|
        doc = Nokogiri::HTML(response.body)
        rows = doc.css("div#roundList table tr")
        rows.delete(rows.first)
        rows.reverse.each do |row|
          round_id = row["onclick"]
          if round_id
            round_id = round_id.split("'")[1]
            round_url = "http://golfshot.com/Rounds/Detail/#{round_id}"
            round_request = Typhoeus::Request.new(round_url, followlocation: true)
            round_request.on_complete do |response|
              doc = Nokogiri::HTML(response.body)
              scorecards << parse_page(doc, round_url, round_id)
            end
            hydra.queue(round_request)
          end
        end
      end

      hydra.queue(page_request)

    end
    hydra.run
    puts "- FINISHED ------------------------------------------------------------------------"
  end

  desc 'Rebuild the databases'
  task :rebuild => [:drop, :create, :migrate, :import]
end



def parse_page(doc, round_url, round_id)
  #date
  date = doc.css("div.roundInfoColLeft h3")[2]
  parsed_date = Date.parse(date.inner_html).to_s

  #course name
  course_title  = doc.css("div.titleBar h2 a").inner_html
  doc.css('div.titleBar').remove


  scorecard = Scorecard.where(golfshot_id: round_id).first
  if scorecard.nil?
    new_or_old = "IMPORTING: "
    scorecard = Scorecard.new(date: parsed_date, course: course_title, golfshot_id: round_id)
  else
    new_or_old = "UPDATING: "
    scorecard.date = parsed_date
    scorecard.course = course_title
    scorecard.scores.each{|s| Score.find(s).destroy }
  end
  puts "------ #{new_or_old} Starting with: course: #{course_title}, date: #{parsed_date}"

  score_objects = []

  #scores
  table_rows = doc.css("div#scorecard table tr")
  i = 0
  19.times do
    i = i+1
    if table_rows[2].css('td')[i].inner_html.to_i > 0
      if table_rows[4].css('td')[i].inner_html.to_i > 0
        score           = Score.new #{id: SecureRandom.uuid}

        score.hole          = table_rows[0].css("td")[i].inner_html.to_i
        score.distance      = table_rows[1].css("td")[i].inner_html.to_i
        score.hcp           = table_rows[2].css("td")[i].inner_html.to_i
        score.par           = table_rows[3].css("td")[i].inner_html.to_i
        score.strokes       = table_rows[4].css("td")[i].inner_html.to_i
        score.points        = table_rows[6].css("td")[i].inner_html.to_i
        score.tee_club      = table_rows[7].css("td")[i].inner_html.to_i
        score.fairway       = table_rows[8].css("td")[i].attr('class')
        #gir is calculated
        score.putts         = table_rows[10].css("td")[i].inner_html.to_i
        score.green_bunker  = table_rows[11].css("td")[i].inner_html.to_i
        score.penalties     = table_rows[12].css("td")[i].inner_html.to_i

        #PICKED UP IN SOME VERSIONS OF GOLFSHOT IS A 7...
        if table_rows[10].css("td")[i].inner_html == "-"
          score.strokes = score.par + 5
          score.putts   = 2
        end

        score.fir   = score.fairway == "bullseye"
        score.gir   = (score.strokes - score.putts) <= (score.par - 2)
        score.strokes_over_par = score.strokes - score.par

        score.name  = NAMES[score.strokes_over_par]

        score.hio           =  score.strokes == 1

        score.scrambling    =  (score.strokes_over_par == 0 && score.gir == false)

        if score.green_bunker > 0
          score.sand_save     =  (score.putts == 1 && score.green_bunker == 1)
        else
          score.sand_save     = nil
        end

        score.up_and_down   =  score.gir ? nil : (score.putts == 1)

        score.user_id ||= USER_ID

        if score.save
          score_objects << score
        end
      end
    end
  end


  #scorecard data
  scorecard.par       = table_rows[3].css('td')[21].inner_html.to_i

  scorecard.strokes_out = table_rows[4].css('td')[10].inner_html.to_i
  scorecard.strokes_in  = table_rows[4].css('td')[20].inner_html.to_i

  scorecard.strokes   = table_rows[4].css('td')[21].inner_html.to_i
  scorecard.points    = table_rows[6].css('td')[21].inner_html.to_i
  scorecard.putts     = table_rows[10].css('td')[21].inner_html.split('/')[1].to_i
  scorecard.putts_avg = table_rows[10].css('td')[21].inner_html.split('/')[0].to_f
  scorecard.putts_out = table_rows[10].css('td')[10].inner_html.to_i
  scorecard.putts_in  = table_rows[10].css('td')[20].inner_html.to_i


  #calculated scorecard data
  scorecard.girs      = score_objects.select{|s| s.gir == true }.length
  scorecard.firs      = score_objects.select{|s| s.fir == true }.length

  scorecard.strokes_over_par    = scorecard.strokes - scorecard.par
  scorecard.scores_count        = score_objects.length
  scorecard.not_par_three_holes = score_objects.select{|s| s.par != 3 }.length

  scorecard.consistency = score_objects.map(&:strokes_over_par)
  scorecard.distance    = score_objects.sum(&:distance)

  pga = (score_objects.select{|s| s.gir?}.inject(0){|sum,x| sum+x.putts}.to_f / scorecard.girs).round(2)
  scorecard.putts_gir_avg = pga.nan? ? 0 : pga

  scorecard.scoring_distribution = [
    (( score_objects.select{|s| s.strokes_over_par == -2 }.size / score_objects.size.to_f) * 100).round(0),
    (( score_objects.select{|s| s.strokes_over_par == -1 }.size / score_objects.size.to_f) * 100).round(0),
    (( score_objects.select{|s| s.strokes_over_par == 0  }.size / score_objects.size.to_f) * 100).round(0),
    (( score_objects.select{|s| s.strokes_over_par == 1  }.size / score_objects.size.to_f) * 100).round(0),
    (( score_objects.select{|s| s.strokes_over_par > 1   }.size / score_objects.size.to_f) * 100).round(0)
  ]

  scorecard.scores = score_objects.map(&:id)

  scorecard.user_id ||= USER_ID

  scorecard.save
end
