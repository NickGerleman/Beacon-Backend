class CreateFirst < ActiveRecord::Migration
  def change
  	create_table :users do |t|
  		t.string :name
  		t.string :password_digest
  	end

  	create_table :sessions do |t|
  		t.belongs_to :user, index: true
  		t.string :token
  	end

  	create_table :beacons do |t|
  		t.belongs_to :user, index: true
  		t.datetime :created_at
  		t.datetime :expires_at
  		t.text :text

  		t.float :latitude
  		t.float :longitude
  		t.float :south_latitude_fence
		t.float :north_latitude_fence
		t.float :west_longitude_fence
		t.float :east_longitude_fence
  	end

  	create_table :votes do |t|
  		t.belongs_to :beacons, index: true
  		t.belongs_to :user, index: true
  		t.integer :value
  	end

  	create_table :photos do |t|
  		t.belongs_to :beacon, index: true
  		t.binary :data
  	end

  	add_index :users, :name, unique: true
  	add_index :sessions, :token, unique: true
  	add_index :beacons, :latitude, unique: false
	add_index :beacons, :longitude, unique: false
	add_index :beacons, :south_latitude_fence, unique: false
	add_index :beacons, :north_latitude_fence, unique: false
	add_index :beacons, :west_longitude_fence, unique: false
	add_index :beacons, :east_longitude_fence, unique: false

  end
end
