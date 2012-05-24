class CreateConferenceDinnerReservations < ActiveRecord::Migration
  def up
    create_table 'conference_dinner_reservations' do |t|
      t.integer 'participant_id', :null => false
      t.decimal 'amount_payed', :scale => 2,  :precision => 4

      t.timestamps
    end

    add_index 'conference_dinner_reservations', 'participant_id'
  end

  def down
    drop_table 'conference_dinner_reservations'
  end
end
