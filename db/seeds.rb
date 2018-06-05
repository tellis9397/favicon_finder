require 'csv'

csv_text = File.read(Rails.root.join('lib', 'seeds', 'top-200k.csv'))
csv = CSV.parse(csv_text, headers: false, encoding: 'ISO-8859-1')
urls = []
csv.each do |row|
	url = URI::HTTP.build({ host: row.last }).to_s

	# urls << Url.new(url: url, fav_url: url + '/favicon.ico')
end
