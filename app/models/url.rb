class Url < ApplicationRecord
	before_save :set_favicon_url
	validate :is_url
	validates :url, presence: true, uniqueness: true

	def set_favicon_url
		# Build favicon url
		favicon_link = url + '/favicon.ico'

		# Check if favicon exists
		begin
			response = HTTParty.get(favicon_link).code
		rescue
			response = 0
		end

		# Set favicon if it exists
		self.fav_url = response == 200 ? favicon_link : nil
	end

	def is_url
		begin
			HTTParty.get(url)
		rescue
			errors.add(:base, 'Must enter working url')
		end
	end
end
