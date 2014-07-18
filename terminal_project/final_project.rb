require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'mailgun'
require_relative 'calendar.rb'
require_relative 'weather_report.rb'

class CalendarWeather
	def initialize
		@agent = Mechanize.new
		@forecasts = {}
		@current_month = Time.now.month
		@current_day = Time.now.day
		@month_days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
		@months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		base
	end
end

start = CalendarWeather.new