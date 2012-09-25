class CreateParticipations < ActiveRecord::Migration
  def up
    create_table 'participations' do |t|
      t.integer 'participant_id', :null => false
      t.integer 'conference_id',  :null => false

      t.boolean 'approved',           :default => false

      t.boolean 'plenary_speaker',    :default => false
      t.boolean 'invited_speaker',    :default => false
      t.boolean 'speaker',            :default => false

      t.date    'arrival_date'
      t.date    'departure_date'

      t.decimal 'registration_fee_payed', :scale => 2,  :precision => 5

      t.text    'committee_comments',   :limit => 1024

      t.timestamps
    end

    add_index 'participations', 'participant_id'
    add_index 'participations', 'conference_id'
    add_index 'participations', 'approved'
  end

  def down
    drop_table 'participations'
  end
end
