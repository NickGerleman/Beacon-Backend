class FixVoteAssociation < ActiveRecord::Migration
  def change
  	remove_reference :votes, :beacons
  	add_reference :votes, :beacon, index: true
  end
end
