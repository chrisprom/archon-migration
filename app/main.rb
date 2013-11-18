
unless RUBY_VERSION =~ /1\.9\.3/
  puts "You are using an unsupported version of Ruby. Please read the README and try again"
  raise "Cannot support #{RUBY_VERSION}"
end

require 'sinatra'
require 'sinatra/assetpack'

require_relative 'lib/startup'
require_relative 'lib/migrate'

Appdata.mode = :server
Appdata.app_dir = File.dirname(__FILE__)

set :port, Appdata.port_number
set :root, File.dirname(__FILE__)
set :show_exceptions, :after_handler

register Sinatra::AssetPack
assets {
  serve '/css',  from: 'css'
  serve '/js/', from: 'js'

  ignore '*-min.css'

  css :application,  [
   '/css/pure/*.css',
   '/css/main.css'
  ]

  js :app, [
		'js/vendor/jquery-2.0.3.min.js',
		'js/vendor/jquery.form.js',
    'js/vendor/jquery.validate.js',
    'js/main.js'
	]
}

Dir.glob(File.dirname(File.absolute_path(__FILE__)) + '/lib/*.rb').each do |f|
  require f
end

public_dir = File.dirname(File.absolute_path(__FILE__)) + '/public'
Dir.mkdir(public_dir) unless File.exists?(public_dir)


get '/' do
  erb :index
end


get '/jobs/new' do
  erb :"jobs/new"
end


post '/jobs' do
  $log.debug("POST /jobs with params: #{params.inspect}")

  Enumerator.new do |y|
    begin
      stamp = Time.now.strftime("%Y-%m-%d-%H-%M-%S")
      $logfile = File.new(Appdata.app_dir + "/public/log-#{stamp}.txt", 'w')
      $syslog = Logger.new($logfile)
      $log = MigrationLog.new(y, $syslog)
      y << JSON.generate({
                           :type => :log, 
                           :file => File.basename($logfile.path)
                         }) + "---\n"

      m = MigrationJob.new(params[:job])
      m.migrate(y)
    rescue JSONModel::ValidationException => e
      body = "Errors: #{e.errors.to_s}"
      if e.respond_to?(:invalid_object)
        body << "<br />Offending record: [ #{e.invalid_object.to_s} ]"
      end
      y << JSON.generate({:type => :error, :body => body}) + "---\n"
    rescue Exception => e
      $log.debug("Server Error: "+e.to_s)
      $log.debug(e.backtrace)
      y << JSON.generate({:type => :error, :body => e.to_s}) + "---\n"
    ensure
      $log = $syslog
      $log.close
    end
  end
end


# post '/jobs' do

#   Enumerator.new do |y|
#     [
#      {:type => :status, :body => "Status 1"},
#      {:type => :update, :body => "Update 1"},
#      {:type => :flash, :body => "Flash 1"},
#      {:type => :flash, :body => "Flash 2", :source => 'aspace'},
#      {:type => :progress, :ticks => "2", :total => "5"},
#      {:type => :progress, :ticks => "4", :total => "5"},
#      {:type => :update, :body => "Update 2"},
#      {:type => :progress, :ticks => "2", :total => "5"},
#      {:type => :progress, :ticks => "4", :total => "5"},
#      {:type => :status, :body => "Status 2"},
#      {:type => :update, :body => "Update 3"},
#     ].each do |msg|
#       y << JSON.generate(msg) + "---\n"
#       sleep(1.0)
#     end
#   end
# end
