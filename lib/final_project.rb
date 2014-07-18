require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'mailgun'

class CalendarWeather
	def initialize
		@agent = Mechanize.new
		@forecasts = {}
		@current_month = Time.now.month
		@current_day = Time.now.day
		@month_days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
		@months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		# base
	end

	def view_calendar
		text = ""
		File.open('calendar.txt', 'r') do |file|
			while line = file.gets
				text += "#{line}<br>"
			end
		end
		text
	end

	def add_item(date, event, place)
		File.open('calendar.txt', 'a') do |file|
			file.print "#{date}: "
			file.print "#{event} "
			file.print "at #{place}.\n"
			File.open('calendar_info.txt', 'a') do |file|
				file.print "#{date};#{event};#{place}\n"
			end
		end
	end

	def delete_item(target)
		File.open('calendar2.txt', 'a') do |new_file|
			File.open('calendar.txt', 'r') do |file|
				while line = file.gets
					if !(line.include? target)
						new_file << line
					end
				end
			end
		end
		File.delete('calendar.txt')
		File.rename('calendar2.txt', 'calendar.txt')

		File.open('calendar_info2.txt', 'a') do |new_file|
			File.open('calendar_info.txt', 'r') do |file|
				while line = file.gets
					if !(line.include? target)
						new_file << line
					end
				end
			end
		end
		File.delete('calendar_info.txt')
		File.rename('calendar_info2.txt', 'calendar_info.txt')
	end

	def weather_search(date, location)
		page = @agent.get("http://www.weather.com")
		location_form = page.form_with(action: "/search/enhancedlocalsearch")
		location_field = location_form.field_with(name: "where")
		location_field.value = location
		page = location_form.submit
		next_page = page.at("a[title = '10 Day']")
		page = @agent.click(next_page)

		weather = Nokogiri::HTML(open("#{page.uri}"))

		if @current_month == date.split('/')[0].to_i
			daycount = date.split('/')[1].to_i - @current_day
		else
			daycount = date.split('/')[1].to_i + @month_days[@current_month] - @current_day
		end

		counter = 0
		weather.css("div.wx-daypart").each do |day|
			if counter == daycount
				day_string = day.css("h3 span.wx-label").text.split
				month_name = day_string[0]
				month_counter = 0
				while month_counter < 12
					if @months[month_counter] == month_name
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
				if daycount == 0
					@forecasts[weather_date][:high_temp] = day.css(high_temp).text.strip.split[0]
				else
					@forecasts[weather_date][:high_temp] = day.css(high_temp).text.strip + "F"
				end

				if daycount != 0
					@forecasts[weather_date][:low_temp] += "F"
				end
			elsif counter > daycount
				break
			end
			counter += 1
		end
	end

	def print_report
		event_dates = []
		event_names = []
		event_locations = []
		File.open('calendar_info.txt', 'r') do |file|
			while line = file.gets
				event_dates << line.split(';')[0]
				event_names << line.split(';')[1]
				event_locations << line.split(';')[2].gsub("\n", "")
			end
		end

		pos = 0
		while pos < event_dates.length do
			weather_search(event_dates[pos], event_locations[pos])
			pos += 1
		end

		@mailgun = Mailgun()

		text = ""
		pos = 0
		@forecasts.each_key do |day|
			text += "On #{day}, you will be #{event_names[pos]} at #{event_locations[pos]}. The conditions will be #{@forecasts[day][:conditions]}. The high temperature will be #{@forecasts[day][:high_temp]}, and the low temperature will be #{@forecasts[day][:low_temp]}. The chance of rain will be #{@forecasts[day][:percent_rain]}, and the wind will blow #{@forecasts[day][:wind]}.\n\n"
			pos += 1
		end

		puts text
	end

	Mailgun.configure do |config|
	  config.api_key = 'key-1gyht3m65176bnmn6ow-rm85c8eq2783'
	  config.domain  = 'sandbox8797a6b096ab495b88abd8e0efadbc58.mailgun.org'
	end

	def weather_report(email)
		event_dates = []
		event_names = []
		event_locations = []
		File.open('calendar_info.txt', 'r') do |file|
			while line = file.gets
				event_dates << line.split(';')[0]
				event_names << line.split(';')[1]
				event_locations << line.split(';')[2].gsub("\n", "")
			end
		end

		pos = 0
		while pos < event_dates.length do
			weather_search(event_dates[pos], event_locations[pos])
			pos += 1
		end

		@mailgun = Mailgun()

		parameters = {
			:to => email,
			:subject => "Weather Report",
			:text => "",
			:from => "postmaster@sandbox8797a6b096ab495b88abd8e0efadbc58.mailgun.org"
		}

		pos = 0
		@forecasts.each_key do |day|
			parameters[:text] += "On #{day}, you will be #{event_names[pos]} at #{event_locations[pos]}. The conditions will be #{@forecasts[day][:conditions]}. The high temperature will be #{@forecasts[day][:high_temp]}, and the low temperature will be #{@forecasts[day][:low_temp]}. The chance of rain will be #{@forecasts[day][:percent_rain]}, and the wind will blow #{@forecasts[day][:wind]}.\n\n"
			pos += 1
		end

		@mailgun.messages.send_email(parameters)
		puts ""
	end
end