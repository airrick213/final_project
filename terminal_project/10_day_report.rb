require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'mailgun'

class WeatherScraper
	def initialize
		@agent = Mechanize.new
		weather_report
	end

	def weather_search
		page = @agent.get("http://www.weather.com")
		location_form = page.form_with(action: "/search/enhancedlocalsearch")
		location_field = location_form.field_with(name: "where")
		puts "What is your location?"
		location_field.value = gets.chomp
		page = location_form.submit
		next_page = page.at("a[title = '10 Day']")
		page = @agent.click(next_page)

		weather = Nokogiri::HTML(open("#{page.uri}"))

		months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		@forecasts = {}
		high_counter = true
		low_counter = true
		weather.css("div.wx-daypart").each do |day|
			day_string = day.css("h3 span.wx-label").text.split
			month_name = day_string[0]
			month_counter = 0
			while month_counter < 12
				if months[month_counter] == month_name
					day_string[0] = (month_counter + 1).to_s
					break
				end
				month_counter += 1
			end

			weather_date = day.css("h3").text.split[0] + " " + day_string[0] + "/" + day_string[1]

			@forecasts[weather_date] = {
				:conditions => day.css("div.wx-conditions p.wx-phrase").text.downcase,
				:high_temp => "",
				:low_temp => day.css("div.wx-conditions p.wx-temp-alt").text.strip,
				:percent_rain => day.css("div.wx-details.wx-event-details-link dl:first-child dd").text,
				:wind => day.css("div.wx-details.wx-event-details-link dl:nth-child(2) dd").text.gsub("\n", "")
			}

			high_temp = "div.wx-conditions p.wx-temp"
			if high_counter
				@forecasts[weather_date][:high_temp] = day.css(high_temp).text.strip.split[0]
			else
				@forecasts[weather_date][:high_temp] = day.css(high_temp).text.strip + "°F"
			end

			if !low_counter
				@forecasts[weather_date][:low_temp] += "F"
			end

			high_counter = false
			low_counter = false
		end
	end

	Mailgun.configure do |config|
	  config.api_key = 'key-1gyht3m65176bnmn6ow-rm85c8eq2783'
	  config.domain  = 'sandbox8797a6b096ab495b88abd8e0efadbc58.mailgun.org'
	end

	def weather_report
		weather_search

		@mailgun = Mailgun()

		puts "What is your email?"
		email = gets.chomp
		parameters = {
			:to => email,
			:subject => "Weather Report",
			:text => "",
			:from => "postmaster@sandbox8797a6b096ab495b88abd8e0efadbc58.mailgun.org"
		}

		@forecasts.each_key do |day|
			parameters[:text] += "#{day}, the conditions are #{@forecasts[day][:conditions]}. The high temperature is #{@forecasts[day][:high_temp]}, and the low temperature is #{@forecasts[day][:low_temp]}. The chance of rain is #{@forecasts[day][:percent_rain]}, and the wind blows #{@forecasts[day][:wind]}.\n\n"
		end

		@mailgun.messages.send_email(parameters)
	end
end

start = WeatherScraper.new