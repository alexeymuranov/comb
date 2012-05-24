class CreateParticipants < ActiveRecord::Migration
  def up
    create_table 'participants' do |t|
      t.string  'last_name',            :limit =>  32,  :null => false
      t.string  'first_name',           :limit =>  32,  :null => false
      t.string  'name_title',           :limit =>  16
      t.string  'email',                :limit => 128
      t.string  'affiliation',          :limit => 128
      t.string  'academic_position',    :limit =>  32
      t.string  'country',              :limit =>  64
      t.string  'city',                 :limit =>  64
      t.string  'post_code',            :limit =>  16
      t.string  'street_address',       :limit => 128
      t.string  'phone',                :limit =>  32

      t.string  'gender',               :limit =>   8

      t.boolean 'approved',           :default => false

      t.boolean 'plenary_speaker',    :default => false
      t.boolean 'invited_speaker',    :default => false
      t.boolean 'speaker',            :default => false
      t.boolean 'student',            :default => false

      t.boolean 'i_m_t_member',       :default => false
      t.boolean 'g_d_r_member',       :default => false

      t.boolean 'visa_needed',        :default => false
      t.boolean 'invitation_needed',  :default => false

      t.date    'arrival_date'
      t.date    'departure_date'

      t.decimal 'registration_fee_payed', :scale => 2,  :precision => 5

      t.string  'office_at_i_m_t',      :limit =>  16

      t.string  'funding_requests'
      t.string  'special_requests'

      t.text    'committee_comments',   :limit => 1024

      t.string  'pin_code_hash',        :limit =>  64

      t.timestamps
    end

    add_index 'participants', ['last_name', 'first_name']
    add_index 'participants', 'approved'
    add_index 'participants', 'visa_needed'
    add_index 'participants', 'invitation_needed'
  end

  def down
    drop_table 'participants'
  end
end
