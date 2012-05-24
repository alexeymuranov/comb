class CreateAccommodations < ActiveRecord::Migration
  def up
    create_table 'accommodations' do |t|
      t.integer 'participant_id', :null => false
      t.integer 'hotel_id',       :null => false

      t.date    'arrival_date'
      t.date    'departure_date'

      t.timestamps
    end

    add_index 'accommodations', 'participant_id'
    add_index 'accommodations', 'hotel_id'
  end

  def down
    drop_table 'accommodations'
  end
end
