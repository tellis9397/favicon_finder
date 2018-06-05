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

	web_response = Url.is_url(url)
	next if web_response.nil?
	favicon_path = Url.get_favicon_string(web_response.to_s, row.last)

	Url.create(url: url, fav_url: url + favicon_path)
end
