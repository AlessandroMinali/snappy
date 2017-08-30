require 'phantomjs'
require 'sinatra'
require 'uri'
require 'data_mapper'
require 'json'
require 'pry'

use Rack::Deflater

# rubocop:disable LineLength

DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_TEAL_URL'] ||
                           "sqlite3://#{Dir.pwd}/gallery.db")

# Schema for Snapshot model
class Snapshot
  include DataMapper::Resource
  property :id, Serial
  property :name, Text, required: true
  property :created_at, DateTime
  property :updated_at, DateTime
  validates_uniqueness_of :name
end

DataMapper.finalize.auto_upgrade!

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def store(image)
    s = Snapshot.new
    s.name = image
    s.created_at = Time.now
    s.updated_at = Time.now
    s.save
  end

  def cached?(image)
    screen_shot = Snapshot.first(name: image)
    if screen_shot && screen_shot.updated_at.to_time < (Time.now - 180)
      true
    else
      false
    end
  end

  def snap(name, url, x, y, mobile = nil)
    agent = mobile ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:35.0) Gecko/20100101 Firefox/35.0' : 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_2 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B440 Safari/600.1.4'
    Phantomjs.run('./public/script/peek.js', url, x, y, "./public/#{name}.png", agent) do |k|
      return false if k.chomp.include? 'timeout'
      store @image if k.chomp.include? 'done'
    end
  end
end

after do
  images = Snapshot.all :created_at.lt => (Time.now - 1800)
  JSON.parse(images.to_json).each do |image|
    begin
      File.delete "./public/#{image['name']}.png"
      File.delete "./public/2#{image['name']}.png"
    rescue
      'file not found'
    end
  end
  images.destroy
end

get '/' do
  @snaps = Snapshot.all limit: 6, order: :updated_at.desc
  erb :index
end

post '/snap' do
  @image = params['url'].split('//')[-1]
  redirect to("/#{@image}")
end

get '/timeout' do
  halt 408, 'website requested took too long to respond<hr><a href="/">Back</a>'
end

get '/api' do
  erb :api
end

get '/about' do
  erb :about
end

get '/:image' do
  @image = params[:image]
  @url = params[:url]
  erb :screen
end

get '/desktop/:image.png' do
  send_file "./public/#{params[:image]}.png"
end

get '/mobile/:image.png' do
  send_file "./public/2#{params[:image]}.png"
end

get '/api/:url/?:format?' do
  content_type :json
  @image = params[:url].split('//')[-1].strip

  params[:url] = 'http://' + params[:url] if params[:url].split('//').length < 2

  if cached? @image
    return { url: params[:url].to_s, desktop: "/desktop/#{@image}.png", mobile: "/mobile/#{@image}.png" }.to_json
  end

  @d = nil
  @m = nil
  status = nil

  if params[:format].nil? || params[:format] == 'desktop'
    status = snap @image, params[:url], '1440', '900'
    @d = "/desktop/#{@image}.png"
  end

  if params[:format].nil? || params[:format] == 'mobile'
    status = snap '2' + @image, params[:url], '640', '960', true
    @m = "/mobile/#{@image}.png"
  end

  halt 404 unless status

  { url: params[:url].to_s, desktop: (@d unless @d.nil?).to_s, mobile: (@m unless @m.nil?).to_s }.to_json
end

not_found do
  halt 404, 'you came to wrong neightbour hood. Page not found.<hr><a href="/">Back</a>'
end

error do
  halt 500, 'Sorry there was a nasty error'
end

# #TODO
# async phantomjs

# stripe checkout and api key give
# api access upon authorization
# privacy of searched websites

# javascript loading page | parallel image grab possibly?

# deploy on heroku
# deploy on DO
