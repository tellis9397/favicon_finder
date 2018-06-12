require 'csv'

csv_text = File.read(Rails.root.join('lib', 'seeds', 'top-200k.csv'))
csv = CSV.parse(csv_text, headers: false, encoding: 'ISO-8859-1')
urls = []
failed = []
csv.each do |row|
	next if Url.where("url LIKE '%#{row.last}%'").any?
	begin
		url = URI::HTTP.build({ host: row.last }).to_s
	rescue
		url = 'http://' + row.last
	end


	Thread.new do
		Rails.application.executor.wrap do
			web_response = Url.is_url(url_record.url)
			unless web_response.nil?
				favicon_url = Url.build_favicon_string(web_response.to_s, http_url, base_url)

				# Add to DB if url exists and return
				ActiveRecord::Base.transaction do
					Url.create(url: url, fav_url: favicon_url)
				end
			end
		end
	end
end
