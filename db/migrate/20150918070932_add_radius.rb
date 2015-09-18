class AddRadius < ActiveRecord::Migration
  def change
  	add_column :beacons, :radius, :float
  end
end
