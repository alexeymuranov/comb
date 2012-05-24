class CreateTalks < ActiveRecord::Migration
  def up
    create_table 'talks' do |t|
      t.string  'type'
      t.integer 'duration_minutes'

      t.integer 'participant_id'

      t.string  'title',          :null => false
      t.text    'abstract'
      t.string  'joint_with'
      t.date    'date'
      t.string  'time'

      t.string  'room_or_auditorium'

      t.timestamps
    end

    add_index 'talks', 'participant_id'
    add_index 'talks', ['title', 'participant_id']
  end

  def down
    drop_table 'talks'
  end
end
