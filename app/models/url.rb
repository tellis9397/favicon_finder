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

				favicon_url = build_favicon_string(web_response.to_s, url_record.url, base_url)

				# Update record
				ActiveRecord::Base.transaction do
					url_record.update_attributes(fav_url: favicon_url)
				end
			end

			return url_record.fav_url
		else
			# Build up http url
			http_url = self.build_http(base_url)

			#Check if url exists and return the response
			web_response = self.is_url(http_url)

			unless web_response.nil?
				favicon_url = build_favicon_string(web_response.to_s, http_url, base_url)

				# Add to DB if url exists and return
				ActiveRecord::Base.transaction do
					return Url.create(url: http_url, fav_url: favicon_url).fav_url
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
			return nil
		end

		response.code == 200 ? response : nil
	end

	# HTTParty will return a response in which I can search for a substring like:
	# <link rel=\"icon\" href=\"http://example.com/favicon.ico\" sizes=\"32x32\"/>
	# I'll need to break down the string to get the favicon route and return
	def self.get_favicon_path(response_string)
		begin
			# Check if the response contains the favicon info
			if response_string.include?("<link rel=\"icon\"")
				favicon_path = response_string.split("<link rel=\"icon\"").last
			elsif response_string.include?("<link rel=\"shortcut icon\"")
				favicon_path = response_string.split("<link rel=\"shortcut icon\"").last
			else
				# No favicon found in response so we'll try at the root
				return '/favicon.ico'
			end
		# Fails on sites with chinese characters due to ruby bug, so we'll just try the root for now
		rescue ArgumentError
			return '/favicon.ico'
		end
		# Breaking down the string until it's just the favicon link
		favicon_path = favicon_path
											.split('>').first
											.split('href=').last
											.gsub("'", '"') # (Some sites put their links in single quotes so let's make it consistant)
											.split('"').second
	end

	def self.strip_url(url)
		url.gsub('https://', '')
			 .gsub('http://', '')
			 .gsub('www.', '')
	end

	def self.build_favicon_string(response, http_url, base_url)
		favicon_path = self.get_favicon_path(response)
		# If the string starts with a forward slash, we add it to the host path
		if (self.strip_url(favicon_path)[0] == '/')
			favicon_url = http_url + favicon_path
		else
			favicon_url = favicon_path
		end

		# Check if favicon exists
		favicon_response = self.is_url(favicon_url)
		favicon_url = nil if favicon_response.nil?
		return favicon_url
	end
end
