require 'csv'

csv_text = File.read(Rails.root.join('lib', 'seeds', 'top-200k.csv'))
csv = CSV.parse(csv_text, headers: false, encoding: 'ISO-8859-1')
urls = []
failed = []
csv.each do |row|
	begin
		url = URI::HTTP.build({ host: row.last }).to_s
	rescue
		url = 'http://' + row.last
	end

	# Allows me to seed in a resonable amount of time,
	# urls without the root will get updated to correct path after a week if/when they are searched.
	Url.create(url: url, fav_url: url + '/favicon.ico')
end
