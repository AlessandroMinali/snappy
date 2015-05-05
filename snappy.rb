require 'phantomjs'
require 'sinatra'
require 'uri'
require 'data_mapper'
require 'json'

DataMapper::setup(:default, ENV['DATABASE_URL'] || "postgres://#{Dir.pwd}/gallery.db")
# DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://user:password@hostname/data/mydatabase.db')
class Snapshot
  include DataMapper::Resource
  property :id, Serial
  property :name, Text, :required => true
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_uniqueness_of :name
end

DataMapper.finalize.auto_upgrade!

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def store image
    s = Snapshot.new
    s.name = image
    s.created_at = Time.now
    s.updated_at = Time.now
    s.save
  end

  def cached? image
    s = Snapshot.first(:name => image)
    if s
      if s.updated_at.to_time < Time.now - 1 * 60

        snap @image, params[:url], '1440', '900'

        snap '2' + @image, params[:url], '640', '960', true

        s.updated_at = Time.now
        s.save
      end
      true
    end
  end

  def snap name, url, x, y, mobile=nil
    mobile.nil? ? agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:35.0) Gecko/20100101 Firefox/35.0' : agent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_2 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B440 Safari/600.1.4'
    Phantomjs.run(
      './public/script/peek.js',
      url,
      x,
      y,
      "./public/#{name}.png",
      agent,
    ) { |k|
        p k
        redirect to('/timeout') if k.chomp.include? 'timeout'
        store @image if k.chomp.include? 'done'
    }
  end
end

after do
  s = Snapshot.all :created_at.lt => Time.now - 2 * 60 * 60 * 24 * 7
  JSON.parse(s.to_json).each { |s|
    File.delete "./public/#{s['name']}.png"
    begin
      File.delete "./public/2#{s['name']}.png"
    rescue
      'file not found'
    end
  }
  s.destroy
end

before '/' do
  next unless request.post?
  redirect to('/'), 'whoops!' unless params['url'] =~ /\A#{URI::regexp(['http', 'https'])}\z/
end

get '/' do
  @snaps = Snapshot.all :limit => 6, :order => :updated_at.desc
  erb :index
end

post '/snap' do
  @image = params['url'].split("//")[-1]

  # redirect to("/#{@image}") unless request.xhr?
  if cached? @image 
    redirect to("/#{@image}")
  end

  snap @image, params[:url], '1440', '900'

  snap '2' + @image, params[:url], '640', '960', true

  # 'status 200'
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
  @image = params[:url].split("//")[-1]

  params[:url] = 'http://' + params[:url] if params[:url].split("//").length < 2

  if cached? @image
    return {url: "#{params[:url]}", desktop: "#{request.host}/desktop/#{@image}.png", mobile: "#{request.host}/mobile/#{@image}.png"}.to_json
  end

  @d, @m = nil, nil

  if params[:format].nil? || params[:format] == 'desktop'
    snap @image, params[:url], '1440', '900'
    @d = "/desktop/#{@image}.png"
  end

  if params[:format].nil? || params[:format] == 'mobile'
    snap '2' + @image, params[:url], '640', '960', true
    @m = "/mobile/#{@image}.png"
  end

  {url: "#{params[:url]}", desktop: "#{request.host + @d unless @d.nil?}", mobile: "#{request.host + @m unless @m.nil?}"}.to_json
end

not_found do
  halt 404, 'you came to wrong neightbour hood. Page not found.<hr><a href="/">Back</a>'
end

error do
  halt 500, 'Sorry there was a nasty error - ' + env['sinatra.error'].name
end

##TODO
# async phantomjs

#stripe checkout and api key give
#api access upon authorization
#privacy of searched websites

#javascript loading page | parallel image grab possibly?

#deploy on heroku
#deploy on DO
