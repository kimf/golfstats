$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), 'models')
require 'yaml'
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'open-uri'

# require 'byebug'

# KIM
USER_ID=1
GOLFSHOT_URL="https://golfshot.com/profiles/mQ0E9/rounds?sb=Date&sd=Descending&p="
# BOLLE
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
      data = JSON.parse(File.read(file))

      next if data["Data"]["Courses"].nil?

      lat = data["MapLat"]
      lng = data["MapLng"]

      club_name = data["Name"]

      club = Club.create(name: club_name, lat: lat, lng: lng)

      data["Data"]["Courses"].each do |c|
        name        = c["Name"]
        holes_count = c["NumberOfHoles"]
        par         = c["Par"]

        course = Course.create(club: club, name: name, holes_count: holes_count, par: par)

        slopes = []
        c["Loop"]["Slopes"].each do |s|
          next if s["Gender"] == 0

          course_rating = s["CourseRating"]
          slope_value   = s["SlopeValue"]
          name          = s["TeeColor"]

          slopes << Slope.create(course: course, course_rating: course_rating, slope_value: slope_value, name: name)
        end

        c["Loop"]["Holes"].each do |h|
          number            = h["Number"]
          par               = h["Par"]
          index             = h["Index"]

          hole = Hole.create(course: course, number: number, par: par, index: index)
        end
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
    # Cache.new.clear #sometimes, stuff works in mysterious ways

    Typhoeus::Config.cache = Cache.new
    Typhoeus::Config.memoize = true

    hydra = Typhoeus::Hydra.new(:max_concurrency => 1000)
    puts "- STARTING ---------------------------------------------------------------"

    scorecards = []

    10.times do |i|
      puts "#{GOLFSHOT_URL}#{i+1}"
      page_request = Typhoeus::Request.new("#{GOLFSHOT_URL}#{i+1}", followlocation: true)

      page_request.on_complete do |response|
        doc = Nokogiri::HTML(response.body)
        rows = doc.css("div.profile-rounds table.search-results tbody tr")
        rows.reverse.each do |row|
          round_href = row["data-href"]
          round_url = "https://golfshot.com#{round_href}"
          round_id = round_href.split('/').last
          round_request = Typhoeus::Request.new(round_url, followlocation: true)
          round_request.on_complete do |round_response|
            doc = Nokogiri::HTML(round_response.body)
            scorecards << parse_page(doc, round_url, round_id)
          end
          hydra.queue(round_request)
        end
      end

      hydra.queue(page_request)
    end
    hydra.run
    puts "- FINISHED ------------------------------------------------------------------------"
  end

  desc 'Rebuild the databases'
  task :rebuild => [:drop, :create, :migrate, :import]

  desc 'Import courses from golfguide'
  task :import_courses do
    # http://golfguide.golfbox.dk/APIS/ScriptHandler.ashx?methodName=GolfSe_GetClubs
    # http://golfguide.golfbox.dk/APIS/ScriptHandler.ashx?methodName=GetClub&guid=72290d5e-b809-4cbf-89e3-38f831b482e6

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
    # Cache.new.clear #sometimes, stuff works in mysterious ways

    Typhoeus::Config.cache = Cache.new
    Typhoeus::Config.memoize = true

    hydra = Typhoeus::Hydra.new(:max_concurrency => 1000)
    puts "- STARTING ---------------------------------------------------------------"

    courses_json = open("http://golfguide.golfbox.dk/APIS/ScriptHandler.ashx?methodName=GolfSe_GetClubs").read
    File.open("_data/golfclubs.json","w+") do |f|
      f.write(courses_json)
    end

    courses = JSON.parse(courses_json)

    courses.each do |course|
      guid = course["GUID"]

      course_json = open("http://golfguide.golfbox.dk/APIS/ScriptHandler.ashx?methodName=GetClub&guid=#{guid}").read
      File.open("_data/courses/#{guid}.json","w+") do |f|
        f.write(course_json)
      end
      c = JSON.parse(course_json)
      puts c.inspect
    end

    hydra.run
    puts "- FINISHED ------------------------------------------------------------------------"
  end
end



def parse_page(doc, _round_url, round_id)
  scripts = doc.search('script')
  scripts.each do |script|
    if script.text.include?('ReactDOM.render')
      text = script.text.split(';').first
      text.slice! 'ReactDOM.render(React.createElement(Golfshot.Applications.Scorecard, '
      json = text.slice(0..(text.index('}), document.getElementById')))

      parsed = JSON.parse(json, object_class: OpenStruct)
      model = parsed.model
      game = model.game.teams[0].players[0]

      # only take 18 holers
      if model.netScore.values.length == 18 && !game.scores[17].score.nil?

        # date
        parsed_date = Date.parse(model.detail.startTime).to_s
        # course name
        course_title = model.detail.facilityName

        # new or updating
        scorecard = Scorecard.where(golfshot_id: round_id).first
        if scorecard.nil?
          new_or_old = "IMPORTING: "
          scorecard = Scorecard.new(date: parsed_date, course: course_title, golfshot_id: round_id)
        else
          new_or_old = "UPDATING: "
          scorecard.date = parsed_date
          scorecard.course = course_title
          scorecard.scores.each{ |s| Score.find(s).destroy }
        end
        puts "------ #{new_or_old} Starting with: course: #{course_title}, date: #{parsed_date}"

        score_objects = []

        18.times do |i|
          score           = Score.new # {id: SecureRandom.uuid}

          index = i-1
          score.strokes       = game.scores[index].score.to_i

          if score.strokes != 0
            score.hole          = i
            score.distance      = model.yardage.yardages[index]
            score.hcp           = model.handicap.values[index]
            score.par           = model.par.values[index]
            # score.points        = table_rows[6].css("td")[i].inner_html.to_i
            score.tee_club      = model.club.values[index]
            score.fairway       = model.fairwayHit.shots[index]
            # gir is calculated
            score.putts         = model.putting.values[index]
            score.green_bunker  = model.sandShots.values[index].to_i
            score.penalties     = model.penalties.values[index]

            # PICKED UP IN SOME VERSIONS OF GOLFSHOT IS A 7...
            if score.putts == "-"
              score.strokes = score.par + 5
              score.putts   = 2
            end

            score.fir   = score.fairway == "Hit"
            score.gir   = model.greensHit.shots[index] == "Hit"
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

        if score_objects.length == 18
          # # scorecard data
          scorecard.par = model.par.total
          scorecard.strokes_out = game.totalOut
          scorecard.strokes_in  = game.totalIn

          scorecard.strokes   = game.total
          # scorecard.points    = model.roundScore.total
          scorecard.putts     = model.putting.total
          scorecard.putts_avg = model.statistics.putting.puttPerHole
          scorecard.putts_out = model.putting.totalOut
          scorecard.putts_in  = model.putting.totalIn


          # # calculated scorecard data
          scorecard.girs      = score_objects.select{ |s| s.gir == true }.length
          scorecard.firs      = score_objects.select{ |s| s.fir == true }.length

          scorecard.strokes_over_par    = scorecard.strokes - scorecard.par
          scorecard.scores_count        = score_objects.length
          scorecard.not_par_three_holes = score_objects.select{ |s| s.par != 3 }.length

          scorecard.consistency = score_objects.map(&:strokes_over_par)
          scorecard.distance    = score_objects.sum(&:distance)

          pga = (score_objects.select{ |s| s.gir? }.inject(0){ |sum,x| sum+x.putts }.to_f / scorecard.girs).round(2)
          scorecard.putts_gir_avg = pga.nan? ? 0 : pga

          scorecard.scoring_distribution = [
            (( score_objects.select{ |s| s.strokes_over_par == -2 }.size / score_objects.size.to_f) * 100).round(0),
            (( score_objects.select{ |s| s.strokes_over_par == -1 }.size / score_objects.size.to_f) * 100).round(0),
            (( score_objects.select{ |s| s.strokes_over_par == 0  }.size / score_objects.size.to_f) * 100).round(0),
            (( score_objects.select{ |s| s.strokes_over_par == 1  }.size / score_objects.size.to_f) * 100).round(0),
            (( score_objects.select{ |s| s.strokes_over_par > 1   }.size / score_objects.size.to_f) * 100).round(0)
          ]

          scorecard.scores = score_objects.map(&:id)

          scorecard.user_id ||= USER_ID
          scorecard.json = json
          scorecard.save
        end
      end
    end
  end
end
