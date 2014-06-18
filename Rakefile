require 'open-uri'
require 'nokogiri'
require 'typhoeus'
require 'debugger'
require 'dalli'
require 'active_support'
require 'active_record'
require 'logger'


ActiveRecord::Base.establish_connection(
  adapter:  "postgresql",
  host:     "localhost",
  database: "golfstats_development",
  username: "kimf",
  password: ""
)
ActiveRecord::Base.logger = Logger.new(STDERR)

ActiveRecord::Migration.class_eval do
  drop_table :scorecards if ActiveRecord::Base.connection.table_exists? 'scorecards'
  drop_table :scores     if ActiveRecord::Base.connection.table_exists? 'scores'

  create_table :scorecards do |t|
    t.date    :date
    t.string  :course

    t.integer :par
    t.integer :out
    t.integer :in
    t.integer :strokes_out
    t.integer :srokes_in
    t.integer :strokes
    t.integer :points
    t.integer :putts
    t.integer :putts_avg
    t.integer :putts_out
    t.integer :putts_in
    t.integer :girs
    t.integer :firs
    t.integer :strokes_over_par
    t.integer :scores_count
    t.integer :not_par_three_holes
    t.integer :distance
    t.string  :consistency
  end

  add_index :scorecards, :date
  add_index :scorecards, :course


  create_table :scores do |t|
    t.integer :scorecard_id
    t.integer :hole
    t.integer :distance
    t.integer :hcp
    t.integer :par
    t.integer :strokes
    t.integer :points
    t.integer :tee_club
    t.integer :fairway
    t.integer :putts
    t.integer :green_bunker, default: nil
    t.integer :penalties, default: nil
    t.integer :fir
    t.integer :gir
    t.integer :strokes_over_par
    t.integer :name
    t.integer :hio
    t.integer :scrambling
    t.integer :sand_save, default: nil
    t.integer :up_and_down, default: nil
  end

  add_index :scores, :scorecard_id
  add_index :scores, :hole
  add_index :scores, :fir
  add_index :scores, :gir
  add_index :scores, :scrambling
  add_index :scores, :sand_save
  add_index :scores, :up_and_down
end

class Scorecard < ActiveRecord::Base
  has_many :scores
end

class Score < ActiveRecord::Base
  belongs_to :scorecard
end

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

desc "Builds and deploys to fransman.se"
task :deploy do
  sh "middleman build"
  sh "middleman deploy"
end


namespace :data do

  desc "Imports scorecards from golfshot.com"
  task :import do

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

    # scorecards.select{|s| s.scores.size < 18 }.each{|s| scorecards.delete(s) }
    # scorecards.select{|s| s.date.include?('2010') }.each{|s| scorecards.delete(s) }

    # scores = []

    # scorecards.each do |s|
    #   scorecard_scores = s.scores
    #   scores << scorecard_scores
    #   s.scores = scorecard_scores.collect{|s| s.id }
    # end

    # data = {scorecards: []}
    # data[:scorecards] = scorecards.sort_by!{|s| s.date }.reverse
    # json = data.to_json
    # File.open("data/scorecards.json","w") do |f|
    #   f.write(json)
    # end

    # data = {scores: []}
    # data[:scores] = scores.to_json
    # json = data.to_json
    # File.open("data/scores.json", "w") do |f|
    #   f.write(json)
    # end

    #18holers = scorecards.select{|s| s.scores_count == 18}
    # average_score
    # average_girs_percentage
    # average_firs_percentage
    # average_gir_putts
    # average_putts
    # consistency


    # File.open("data/player.json","w") do |f|
    #   f.write(json)
    # end

    puts "- FINISHED ------------------------------------------------------------------------"
  end
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

        scorecard.scores << score
      end
    end
  end


  #scorecard data
  scorecard.par       = table_rows[3].css('td')[21].inner_html.to_i
  scorecard.out       = table_rows[4].css('td')[10].inner_html.to_i
  scorecard.in        = table_rows[4].css('td')[20].inner_html.to_i

  scorecard.strokes   = table_rows[4].css('td')[21].inner_html.to_i
  scorecard.points    = table_rows[6].css('td')[21].inner_html.to_i
  scorecard.putts     = table_rows[10].css('td')[21].inner_html.split('/')[1].to_i
  scorecard.putts_avg = table_rows[10].css('td')[21].inner_html.split('/')[0].to_f
  scorecard.putts_out = table_rows[10].css('td')[10].inner_html.to_i
  scorecard.putts_in  = table_rows[10].css('td')[20].inner_html.to_i


  #calculated scorecard data
  scorecard.girs      = scorecard.scores.select{|s| s.gir == true }.length
  scorecard.firs      = scorecard.scores.select{|s| s.fir == true }.length

  scorecard.strokes_over_par    = scorecard.strokes - scorecard.par
  scorecard.scores_count        = scorecard.scores.length
  scorecard.not_par_three_holes = scorecard.scores.select{|s| s.par != 3 }.length

  scorecard.consistency = scorecard.scores.map{|s| s.strokes_over_par }.join(',')
  scorecard.distance    = scorecard.scores.map{|s| s.distance.to_i }.inject(:+)

  #scorecard.scrambling_percentage = ((scramblings.to_f/missed_greens.to_f)*100)

  scorecard.save
end
