class Url < ApplicationRecord
	validates :url, presence: true, uniqueness: true

	def self.get_favicon(url)
		# Break down input to base url.
		# Removing the beginning here makes it easier to remove '/' after the base url
		base_url = url.gsub('https://', '').gsub('http://', '').gsub('www.', '').split('/').first

		# Check the DB
		url_record = Url.where("url LIKE '%#{base_url}%'")

		if url_record.any?
			return url_record.first.fav_url
		else
			# URI doesn't accept underscores so we'll just try the hacky solution
			if base_url.include?('_')
				http_url = 'http://' + base_url
			else
				http_url = URI::HTTP.build({ host: base_url }).to_s
			end

			# Add to DB if url exists and return
			if (self.is_url(http_url))
				ActiveRecord::Base.transaction do
					Url.create(url: url, fav_url: url + '/favicon.ico').fav_url
				end
			else
				nil
			end
		end
	end

	def self.is_url(url)
		begin
			response = HTTParty.get(url).code
		rescue
			response = 0
		end

		response == 200 ? true : false
	end
end
