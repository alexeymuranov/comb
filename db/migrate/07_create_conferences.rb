# encoding: UTF-8 (magic comment)

class CreateConferences < ActiveRecord::Migration
  def up
    create_table 'conferences' do |t|
      t.string  'identifier', :null => false
      t.integer 'number'
      t.string  'en_title',   :null => false
      t.string  'fr_title',   :null => false

      t.text    'description',  :limit => 4096

      t.date    'start_date'
      t.date    'end_date'

      t.string  'location'

      t.text    'comments',     :limit => 4096

      t.timestamps
    end

    Conference.create!(
      :identifier => 'Intro',
      :number     => 1,
      :en_title   => 'Introductory week',
      :fr_title   => 'Semaine d\'introduction',
      :start_date => '2013-05-27',
      :end_date   => '2013-05-31',
      :location   => 'IMT')
    Conference.create!(
      :identifier => 'GESTA',
      :number     => 2,
      :en_title   => 'GESTA workshop',
      :fr_title   => 'Semaine « GESTA »',
      :start_date => '2013-06-03',
      :end_date   => '2013-06-07',
      :location   => 'IMT')
    Conference.create!(
      :identifier => 'Llagone',
      :number     => 3,
      :en_title   => 'Summer school on Donaldson hypersurfaces',
      :fr_title   => 'École d\'été autour des hypersurfaces de Donaldson',
      :start_date => '2013-06-17',
      :end_date   => '2013-06-21',
      :location   => 'Llagone')
    Conference.create!(
      :identifier => 'CoMB',
      :number     => 4,
      :en_title   => 'Low-dimensional Topology and Geometry in Toulouse',
      :fr_title   => 'Topologie et Géométrie en petite dimension à Toulouse',
      :start_date => '2013-06-24',
      :end_date   => '2013-06-28',
      :location   => 'IMT')

    add_index 'conferences', 'identifier', :unique => true
  end

  def down
    drop_table 'conferences'
  end
end
