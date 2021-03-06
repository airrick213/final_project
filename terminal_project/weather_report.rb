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

def weather_report
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

	puts "What is your email?"
	email = gets.chomp
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