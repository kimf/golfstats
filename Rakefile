$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), 'models')
require 'yaml'
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'open-uri'


Dir["./backend/models/*.rb"].each do |file|
 require "./#{file}"
end

@environment = ENV['RACK_ENV'] || 'development'
@dbconfig = YAML.load(File.read('backend/database.yml'))
ActiveRecord::Base.establish_connection @dbconfig[@environment]
ActiveRecord::Base.logger = Logger.new(STDOUT)




namespace :db do

  desc "do migrations"
  task :migrate do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate "backend/db/migrate", ENV['VERSION'] ? ENV['VERSION'].to_i : nil
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

  desc "Imports scorecards from golfshot.com"
  task :import do

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
    doc = Nokogiri::HTML(open("http://golfshot.com/members/0192098630/rounds"))

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
            round_url = "http://golfshot.com/Rounds/Detail/#{round_id.split("'")[1]}"
            round_request = Typhoeus::Request.new(round_url, followlocation: true)
            round_request.on_complete do |response|
              doc = Nokogiri::HTML(response.body)
              scorecards << parse_page(doc, round_url)
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



def parse_page(doc, round_url)
  #date
  date = doc.css("div.roundInfoColLeft h3")[2]
  parsed_date = Date.parse(date.inner_html).to_s

  #course name
  course_title  = doc.css("div.titleBar h2 a").inner_html
  doc.css('div.titleBar').remove

  puts "------ Starting with: course: #{course_title}, date: #{parsed_date}"

  scorecard = Scorecard.new(date: parsed_date, course: course_title)
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

  #scorecard.scrambling_percentage = ((scramblings.to_f/missed_greens.to_f)*100)

  scorecard.scores = score_objects.map(&:id)

  scorecard.save
end
