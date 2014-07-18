def base
	while true
		puts "What would you like to do? (View Calendar, Add Item, Delete Item, Weather Report, Quit)"
		@action = gets.chomp.downcase

		if @action == "view calendar"
			view_calendar
		elsif @action == "add item"
			add_item
		elsif @action == "delete item"
			delete_item
		elsif @action == "print report"
			print_report
		elsif @action == "email report"
			weather_report
		elsif @action == "quit"
			break
		else
			puts "Sorry, that wasn't a valid option."
		end
	end
end

def view_calendar
	File.open('calendar.txt', 'r') do |file|
		while line = file.gets
			puts line
		end
	end
	puts ""
end

def add_item
	File.open('calendar.txt', 'a') do |file|
		puts "What is your event's date?"
		date = gets.chomp
		file.print "#{date}: "

		puts "What will you be doing?"
		event = gets.chomp
		file.print "#{event} "

		puts "Where?"
		place = gets.chomp
		file.print "at #{place}.\n"

		File.open('calendar_info.txt', 'a') do |file|
			file.print "#{date};#{event};#{place}\n"
		end
	end
	puts ""
end

def delete_item
	view_calendar
	puts "What would you like to delete? (Action)"
	target = gets.chomp
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

	puts ""
	puts "Here's what you have left:"
	view_calendar
end