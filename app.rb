require 'sinatra'
require "sinatra/activerecord"
require "sinatra/json"
require 'geokit'

Geokit::default_units = :kms

class Session < ActiveRecord::Base
	belongs_to :user
	before_create { self.token = SecureRandom.urlsafe_base64 }
end

class User < ActiveRecord::Base
	has_many :beacons, dependent: :destroy
	has_many :sessions, dependent: :destroy
	has_many :votes, dependent: :destroy
	has_secure_password

	validates :name, uniqueness: {case_sensitive: false}
	validates :password, presence: true
end

class Vote < ActiveRecord::Base
	belongs_to :user
	belongs_to :beacon
end

class Beacon < ActiveRecord::Base
	belongs_to :user
	has_many :photos, dependent: :destroy
	has_many :votes, dependent: :destroy
	scope :expired, -> { where "expires_at < ?", Time.now }
	
	# Create boundaries for fast lookup using indexes
	before_create :calculate_fence
	# Remove everything that has expired after making something new
	after_create { Beacon.expired.destroy_all }

	def score
		self.votes.sum(:value)	
	end

	def username
		self.user.name
	end

	def distance_to(location)
		location.distance_to(Geokit::LatLng.new(self.latitude, self.longitude))
	end

	def self.visibible_from(location)
		expired.destroy_all

		fenced_beacons = Beacon.includes(:votes).where "south_latitude_fence <= :lat
									AND north_latitude_fence >= :lat
									AND west_longitude_fence <= :lon
									AND east_longitude_fence >= :lon",
									{lat: location.latitude, lon: location.longitude}

		return fenced_beacons.select {|beacon| beacon.distance_to(location) <= beacon.radius}
	end

	private

	def self.bearing_to_location(location, distance_km, bearing)
		geo_loc = Geokit::LatLng.new(location.latitude, location.longitude)

	end


	# Set the fence latitude and longitudes
	def calculate_fence
		this_location = Geokit::LatLng.new(self.latitude, self.longitude)

		self.south_latitude_fence = this_location.endpoint(180, self.radius).latitude
		self.north_latitude_fence = this_location.endpoint(0, self.radius).latitude
		self.west_longitude_fence = this_location.endpoint(270, self.radius).longitude
		self.east_longitude_fence = this_location.endpoint(90, self.radius).longitude
	end

end

class Photo < ActiveRecord::Base
	belongs_to :beacon

	def url
		"/photo/#{self.id}"
	end
end


# Grab sesion and user
before do
	request.env["HTTP_AUTHORIZATION"].try(:match, "Token (.*)") do |m|
		token = m[1]
		@session = Session.includes(:user).find_by_token(token)
		@user = @session.user if @session
	end
end

get '/beacon/'  do
	return 401 unless @user 
	return 400 unless params[:latitude] && params[:longitude]

	beacons = Beacon.visibible_from(Geokit::LatLng.new(params[:latitude], params[:longitude]))

	beacons.map! do |beacon| 
		serialized_beacon = beacon.as_json(only: [:id, :created_at, :expires_at, :text, :latitude, :longitude, :radius],
										   methods: [:score, :username],
										   include: { photos: { only: [], methods: :url } })
		#Only have url for photos
		if serialized_beacon["photos"].empty?
			serialized_beacon.delete("photos")
		else
			serialized_beacon["photos"].map! {|photo| photo["url"] }
		end
		serialized_beacon["my_vote"] = beacon.votes.select {|vote| vote.user.id == @user.id}[0].try(:value) || 0
		
		serialized_beacon
	end

	json beacons: beacons
end

post '/beacon'  do
	return 401 unless @user
	return 400 unless params[:latitude] && params[:longitude] && params[:text] && params[:radius] && params[:expires_at]

	beacon = @user.beacons.new(params.delete_if {|k, v| k == 'photos'})
	return 400 if beacon.invalid?

	params[:photos].try(:each) do |photo| 
		beacon.photos.new(data: photo[:tempfile].read)
	end

	beacon.save
	201
end

put '/beacon/:id/vote' do
	return 401 unless @user
	
	begin
		value = Integer(params[:value])
	rescue ArgumentError
		400
	end

	return 400 unless value >= -1 && value <= 1
	beacon = Beacon.find(params[:id])
	return 404 unless beacon

	# Handle any existing votes
	existing_vote = Vote.where(user_id: @user.id, beacon_id: beacon.id)
	existing_vote.destroy_all if existing_vote

	beacon.votes.create(value: value, user: @user) unless value == 0
	200
end

get '/photo/:id' do
	photo = Photo.find(params[:id])
	return 404 unless photo

	content_type :jpg
	photo.data
end

post '/user' do 
	user = User.new(params)
	return 400 if user.invalid?

	user.save
	session = user.sessions.create
	json token: session.token
end

post '/session' do
	return 400 unless params[:name] && params[:password]
	user = User.find_by_name(params[:name])
	return 404 unless user && user.authenticate(params[:password])

	session = user.sessions.create
	json token: session.token	
end