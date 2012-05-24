class CreateTalkProposals < ActiveRecord::Migration
  def up
    create_table 'talk_proposals' do |t|
      t.integer 'participant_id', :null => false
      t.integer 'talk_id'
      t.integer 'duration_minutes'
      t.string  'type'
      t.string  'title'
      t.text    'abstract'

      t.timestamps
    end

    add_index 'talk_proposals', 'participant_id', :unique => true
    add_index 'talk_proposals', 'talk_id',        :unique => true
  end

  def down
    drop_table 'talk_proposals'
  end
end
