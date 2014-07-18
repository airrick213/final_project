require 'bundler' #require bundler
Bundler.require #require everything in bundler in gemfile
require 'pry'
require './lib/final_project.rb'

get '/' do
	scraper = CalendarWeather.new
	@calendar = scraper.view_calendar
	scraper.add_item(@date, @action, @place)
	scraper.delete_item(@delete_target)
	scraper.weather_report(@email)
	erb :index
end

post '/' do
	@date = params[:date]
	@action = params[:action]
	@place = params[:place]
	@delete_target = params[:delete_target]
	@email = params[:email]
	erb :index, :locals => {'date' => @date, 'action' => @action, 'place' => @place, 'delete_target' => @delete_target, 'email' => @email}
end