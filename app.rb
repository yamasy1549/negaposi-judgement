require "twitter"
require "net/http"
require "uri"
require "json"
require "dotenv"

Dotenv.load

def get_json(location, limit = 10)
  raise ArgumentError, 'too many HTTP redirects' if limit == 0
  uri = URI.parse(location)
  begin
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.open_timeout = 5
      http.read_timeout = 10
      http.get(uri.request_uri)
    end
    case response
    when Net::HTTPSuccess
      json = response.body
      JSON.parse(json)
    when Net::HTTPRedirection
      location = response['location']
      warn "redirected to #{location}"
      get_json(location, limit - 1)
    else
      puts [uri.to_s, response.value].join(" : ")
      # handle error
    end
  rescue => e
    puts [uri.to_s, e.class, e].join(" : ")
    # handle error
  end
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
  config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
  config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
end

count = 0
nega = 0
posi = 0

client.user_timeline("yamasy1549", { count: ARGV[0] ||= 100 }).each do |tweet|
  if tweet.created_at.day == Time.now.day
    json = get_json("http://ap.mextractr.net/ma9/negaposi_analyzer?out=json&apikey=#{ENV["NEGAPOSI_API_KEY"]}&text=#{URI.encode(tweet.text)}")
    score = json.dig("negaposi")
    puts tweet.text
    puts score
    score < 0 ? nega -= score : posi += score
    count += 1
  else
    content = "きょうの直近#{count}ツイートにおけるやましーの\nポジティブ度は #{posi}\nネガティブ度は #{nega}\n徳は #{posi - nega}\nです。\n徳高めていこうな✋"
    puts content
    client.update content
    exit
  end
end
