# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150918075130) do

  create_table "beacons", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "expires_at"
    t.text     "text"
    t.float    "latitude"
    t.float    "longitude"
    t.float    "south_latitude_fence"
    t.float    "north_latitude_fence"
    t.float    "west_longitude_fence"
    t.float    "east_longitude_fence"
    t.float    "radius"
  end

  add_index "beacons", ["east_longitude_fence"], name: "index_beacons_on_east_longitude_fence"
  add_index "beacons", ["latitude"], name: "index_beacons_on_latitude"
  add_index "beacons", ["longitude"], name: "index_beacons_on_longitude"
  add_index "beacons", ["north_latitude_fence"], name: "index_beacons_on_north_latitude_fence"
  add_index "beacons", ["south_latitude_fence"], name: "index_beacons_on_south_latitude_fence"
  add_index "beacons", ["user_id"], name: "index_beacons_on_user_id"
  add_index "beacons", ["west_longitude_fence"], name: "index_beacons_on_west_longitude_fence"

  create_table "photos", force: :cascade do |t|
    t.integer "beacon_id"
    t.binary  "data"
  end

  add_index "photos", ["beacon_id"], name: "index_photos_on_beacon_id"

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id"
    t.string  "token"
  end

  add_index "sessions", ["token"], name: "index_sessions_on_token", unique: true
  add_index "sessions", ["user_id"], name: "index_sessions_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "password_digest"
  end

  add_index "users", ["name"], name: "index_users_on_name", unique: true

  create_table "votes", force: :cascade do |t|
    t.integer "user_id"
    t.integer "value"
    t.integer "beacon_id"
  end

  add_index "votes", ["beacon_id"], name: "index_votes_on_beacon_id"
  add_index "votes", ["user_id"], name: "index_votes_on_user_id"

end
