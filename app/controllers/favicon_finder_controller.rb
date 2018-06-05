class FaviconFinderController < ApplicationController
	rescue_from ActionView::Template::Error, with: :favicon_not_found

	def home
		@has_searched = false
		# TODO maybe move all this logic to the url model
		if params[:search]
			@has_searched = true

			@favicon = Url.get_favicon(params[:search])
		end
	end

	def respond_to_error
		respond_to do |format|
			format.html { render :home }
			format.json { render json: @url.errors, status: :unprocessable_entity }
		end
	end

	# No asset found for fav_url
	# Likely valid url but no favicon
	def favicon_not_found
		flash[:alert] = 'No Favicon for this url'
		render 'home'
	end
end