class Url < ApplicationRecord
	validates :url, presence: true, uniqueness: true

	def self.get_favicon(url)
		# Break down input to base url.
		# Removing the beginning here makes it easier to remove '/' after the base url
		base_url = self.strip_url(url).split('/').first

		# Check the DB
		# After a record has been added, a user can just input the website name
		url_records = Url.where("url LIKE '%#{base_url}%'")


		if url_records.any?
			url_record = url_records.first
			# Get fresh favicon if the record hasn't been updated in a week
			unless (Time.current.to_date - url_record.updated_at.to_date).to_i < 7
				web_response = self.is_url(url_record.url)

				return nil if web_response.nil?

				favicon_path = self.get_favicon_string(web_response.to_s, base_url)
				# Update record
				ActiveRecord::Base.transaction do
					url_record.update_attributes(fav_url: url_record.url + favicon_path)
				end
			end

			return url_record.fav_url
		else
			# Build up http url
			http_url = self.build_http(base_url)

			#Check if url exists and return the response
			web_response = self.is_url(http_url)

			unless web_response.nil?
				favicon_path = self.get_favicon_string(web_response.to_s, base_url)

				# Add to DB if url exists and return
				ActiveRecord::Base.transaction do
					return Url.create(url: http_url, fav_url: http_url + favicon_path).fav_url
				end
			end

			return nil
		end
	end

	def self.build_http(url)
		if url.include?('_')
			# URI doesn't accept underscores so we'll just try the hacky solution
			http_url = 'http://' + url
		else
			http_url = URI::HTTP.build({ host: url }).to_s
		end
	end

	def self.is_url(url)
		begin
			response = HTTParty.get(url)
		rescue
			response = 0
		end

		response.code == 200 ? response : nil
	end

	# HTTParty will return a response in which I can search for a substring like:
	# <link rel=\"icon\" href=\"http://example.com/favicon.ico\" sizes=\"32x32\"/>
	# I'll need to break down the string to get the favicon route and return
	def self.get_favicon_string(response_string, url)
		# Check if the response contains the favicon info
		if response_string.include?("<link rel=\"icon\"")
			favicon_string = response_string.split("<link rel=\"icon\"").last
		elsif response_string.include?("<link rel=\"shortcut icon\"")
			favicon_string = response_string.split("<link rel=\"shortcut icon\"").last
		else
			# No favicon found in response so we'll try at the root
			return '/favicon.ico'
		end
		# Breaking down the string until it's just the favicon link
		favicon_string = favicon_string
											.split('>').first
											.split('href=').last
											.split('"').second

		# Some responses just contain a path from the host,
		# so we'll treat them all the same to make things easier
		self.strip_url(favicon_string).gsub(url, '')
	end

	def self.strip_url(url)
		url.gsub('https://', '')
			 .gsub('http://', '')
			 .gsub('www.', '')
	end
end
