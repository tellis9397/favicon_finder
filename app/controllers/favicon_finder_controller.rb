class FaviconFinderController < ApplicationController
	def home
		@has_searched = false

		if params[:search]
			@has_searched = true
			# Break down input to base url.
			# Removing 'https' here makes it easier to remove '/' after the base url
			base_url = params[:search].gsub('https://', '').split('/').first

			# Check the DB
			url_record = Url.where("url LIKE '%#{base_url}%'")

			# Build up favicon link if url does not exist
			if url_record.empty?
				# Build url back up
				http_url = URI::HTTP.build({ host: base_url }).to_s

				@url = Url.new(url: http_url)
				ActiveRecord::Base.transaction do
					unless @url.save
						respond_to_error
					end
				end
			# Or user requests fresh favicon
			elsif params[:get_fresh]
				@url = url_record.first
				unless @url.save
					respond_to_error
				end
			else
				@url = url_record.first
			end
		end
	end

	def respond_to_error
		respond_to do |format|
			format.html { render :home }
			format.json { render json: @url.errors, status: :unprocessable_entity }
		end
	end
end