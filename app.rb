require 'bundler' #require bundler
Bundler.require #require everything in bundler in gemfile
require 'pry'
require './lib/final_project.rb'

get '/' do
	@scraper = CalendarWeather.new
	@calendar = @scraper.view_calendar
	@date = nil
	@action = nil
	@place = nil
	@delete_target = nil
	@email = nil
	erb :index
end

post '/' do
	@date = params[:date]
	@action = params[:action]
	@place = params[:place]
	@delete_target = params[:delete_target]
	@email = params[:email]
	@scraper = CalendarWeather.new
	if @date != nil
		@scraper.add_item(@date, @action, @place)
	elsif @delete_target != nil
		@scraper.delete_item(@delete_target)
	elsif @email != nil
		@scraper.weather_report(@email)
	end
	@calendar = @scraper.view_calendar
	erb :index, :locals => {'date' => @date, 'action' => @action, 'place' => @place, 'delete_target' => @delete_target, 'email' => @email}
end