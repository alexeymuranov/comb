# encoding: UTF-8 (magic comment)

require 'digest' # hash function

require './lib/attribute_types' # my custom module

# Internationalisation
# NOTE: normally should be used only in decorators and presenters
require 'i18n'

class Conference < ActiveRecord::Base
  self.table_name = :conferences

  include AttributeTypes

  # Associations
  has_many :participations, :class_name  => :Participation,
                            :foreign_key => :conference_id,
                            :inverse_of  => :conference

  has_many :participants, :through => :participations,
                          :source  => :participant

  # Scopes
  scope :default_order, order("#{ table_name }.start_date ASC")

  # Public class methods
  def self.intro_conf
    where(:identifier => 'Intro').first
  end

  def self.g_e_s_t_a_conf
    where(:identifier => 'GESTA').first
  end

  def self.llagone_conf
    where(:identifier => 'Llagone').first
  end

  def self.co_m_b_conf
    where(:identifier => 'CoMB').first
  end

  # Public instance methods
  # NOTE: should probably be accessed through a decorator
  def title(locale = I18n.locale)
    title_attr_name = "#{ locale }_title"
    respond_to?(title_attr_name) ? public_send(title_attr_name) : en_title
  end

  # NOTE: should probably be accessed through a decorator
  def title_with_details(locale = I18n.locale)
     "#{ title(locale) }" \
       " (#{ location }," \
       " #{ I18n.l(start_date, :locale => locale) }" \
       " — #{ I18n.l(end_date, :locale => locale) })"
  end
end

class Participation < ActiveRecord::Base
  self.table_name = :participations

  include AttributeTypes

  # Associations
  belongs_to :participant, :class_name  => :Participant,
                           :foreign_key => :participant_id,
                           :inverse_of  => :participations

  belongs_to :conference, :class_name   => :Conference,
                           :foreign_key => :conference_id,
                           :inverse_of  => :participations

  has_many :talks, :class_name  => :Talk,
                   :foreign_key => :participation_id,
                   :dependent   => :nullify,
                   :inverse_of  => :participation

  has_one :talk_proposal, :class_name  => :TalkProposal,
                          :foreign_key => :participation_id,
                          :dependent   => :destroy,
                          :inverse_of  => :participation

  has_one :conference_dinner_reservation,
          :class_name  => :ConferenceDinnerReservation,
          :foreign_key => :participation_id,
          :dependent   => :destroy,
          :inverse_of  => :participation

  accepts_nested_attributes_for :talk_proposal, :reject_if     => :all_blank,
                                                :allow_destroy => true,
                                                :update_only   => true

  # Validations

  # Scopes
  scope :approved, where(:approved => true)
  scope :not_approved, where(:approved => false)
  scope :plenary_speakers, where(:plenary_speaker => true)
  scope :sectional_speakers, where(:speaker => true, :plenary_speaker => false)
  scope :non_speakers, where(:speaker => false)
  scope :invited_speakers, where(:invited_speaker => true)

  # Overwrite default accessors
  def speaker=(bool)
    unless write_attribute(:speaker, bool)
      write_attribute(:pleanry_speaker, false)
      write_attribute(:invited_speaker, false)
    end
  end

  def pleanry_speaker=(bool)
    if write_attribute(:plenary_speaker, bool)
      write_attribute(:speaker, true)
    end
  end

  def invited_speaker=(bool)
    if write_attribute(:invited_speaker, bool)
      write_attribute(:speaker, true)
    end
  end
end

class Participant < ActiveRecord::Base
  self.table_name = :participants

  include AttributeTypes

  # Associations
  has_many :participations, :class_name  => :Participation,
                            :foreign_key => :participant_id,
                            :inverse_of  => :participant,
                            # :include     => :conference,
                            :autosave    => true

  has_many :conferences, :through => :participations,
                         :source  => :conference

  has_many :talks, :through => :participations,
                   :source  => :talks

  has_many :talk_proposals, :through => :participations,
                            :source  => :talk_proposal

  has_many :accommodations, :class_name  => :Accommodation,
                            :foreign_key => :participant_id,
                            :inverse_of  => :participant

  has_many :hotels, :through => :accommodations,
                    :source  => :hotel

  has_many :conference_dinner_reservations,
           :through => :participations,
           :source  => :conference_dinner_reservation

  accepts_nested_attributes_for :participations, :reject_if     => :all_blank,
                                                 :allow_destroy => true,
                                                 :update_only   => true

  # Validations
  validates_presence_of :first_name,
                        :last_name

  validates_length_of :first_name, :last_name,
                      :maximum => 32

  validates_length_of :name_title, :maximum   => 16,
                                   :allow_nil => true

  validates_format_of :email,
                      :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  validates_inclusion_of :gender,
                         :in        => ['female', 'male', :female, :male],
                         :allow_nil => true

  validates_uniqueness_of :first_name, :scope         => :last_name,
                                       :case_sesitive => false

  validates_uniqueness_of :email

  # Validaton of assocaitions
  validates_presence_of :participations

  # Scopes
  scope :default_order, order("UPPER(#{ table_name }.last_name) ASC").
                          order("UPPER(#{ table_name }.first_name) ASC")

  scope :approved, joins(:participations).merge(Participation.approved).uniq

  scope :not_all_participations_approved, joins(:participations).merge(Participation.not_approved).uniq

  # Virtual attributes
  def full_name
    "#{ first_name } #{ last_name }"
  end

  def full_name_with_affiliation
    affiliation ? "#{ full_name } (#{ affiliation })" : full_name
  end

  def new_pin; @new_pin end

  def approved
    participations.approved.any?
  end

  alias_method :approved?, :approved

  # CoMB related
  def co_m_b_participation
    participations.where(:conference_id => Conference.co_m_b_conf.id).first
  end

  def co_m_b_committee_comments
    co_m_b_participation.committee_comments if co_m_b_participation
  end

  def co_m_b_talk_proposal
    co_m_b_participation.talk_proposal if co_m_b_participation
  end

  # Public instance methods
  def generate_pin
    @new_pin = Digest::SHA2.hexdigest(rand.to_s)[0..3]
    self.pin_code_hash = Digest::SHA2.base64digest(@new_pin)
    @new_pin
  end

  def accept_pin?(pin)
    Digest::SHA2.base64digest(pin) == pin_code_hash
  end
end

class Talk < ActiveRecord::Base
  self.table_name = :talks
  self.inheritance_column = :type

  include AttributeTypes

  # Associations
  belongs_to :conference_speaker, :class_name  => :Participation,
                                  :foreign_key => :participation_id,
                                  :inverse_of  => :talks

  has_one :conference, :through => :conference_speaker,
                       :source  => :conference

  has_one :speaker, :through => :conference_speaker,
                    :source  => :participant

  has_one :original_proposal, :class_name  => :TalkProposal,
                              :foreign_key => :talk_id,
                              :dependent   => :nullify,
                              :inverse_of  => :talk

  # Validations
  validates_presence_of :type,
                        :participant_id,
                        :title

  validates_inclusion_of :type, :in => %w[PlenaryTalk ParallelTalk]

  # Readonly attributes
  attr_readonly :participation_id

  # Scopes
  scope :default_order, order("UPPER(talks.title) ASC")

  # Virtual attributes
  def speaker_name
    speaker.full_name
  end

  def title_with_speaker
    "#{ speaker_name }: \"#{ title }\""
  end

  def translated_type_name
    self.class.model_name.human
  end
end

class PlenaryTalk < Talk
  DURATION_MINUTES = 60

  before_save :set_duration

  private

    def set_duration
      self.duration_minutes = DURATION_MINUTES
    end

end

class ParallelTalk < Talk
  DURATION_MINUTES = 30

  before_save :set_duration

  private

    def set_duration
      self.duration_minutes = DURATION_MINUTES
    end

end

class Hotel < ActiveRecord::Base
  self.table_name = :hotels

  include AttributeTypes

  # Associations
  has_many :accommodations, :class_name  => :Accommodation,
                            :foreign_key => :hotel_id,
                            :inverse_of  => :hotel

  has_many :participants, :through => :accommodations,
                          :source  => :participant

  # Validations
  validates_presence_of :name

  # Scopes
  scope :default_order, order("UPPER(hotels.name) ASC")
end

class Accommodation < ActiveRecord::Base
  self.table_name = :accommodations

  include AttributeTypes

  # Associations
  belongs_to :participant, :class_name  => :Participant,
                           :foreign_key => :participant_id,
                           :inverse_of  => :accommodations

  belongs_to :hotel, :class_name  => :Hotel,
                     :foreign_key => :hotel_id,
                     :inverse_of  => :accommodations

  # Validations
  validates_presence_of :participant_id,
                        :hotel_id

  # Readonly attributes
  attr_readonly :participant_id, :hotel_id
end

class ConferenceDinnerReservation < ActiveRecord::Base
  self.table_name = :conference_dinner_reservations

  include AttributeTypes

  # Associations
  belongs_to :participation, :class_name  => :Participation,
                             :foreign_key => :participation_id,
                             :inverse_of  => :conference_dinner_reservation

  # Readonly attributes
  attr_readonly :participatioin_id
end

class TalkProposal < ActiveRecord::Base
  self.table_name = :talk_proposals

  include AttributeTypes

  # Associations
  belongs_to :participation, :class_name  => :Participation,
                             :foreign_key => :participation_id,
                             :inverse_of  => :talk_proposal

  has_one :participant, :through => :participation,
                        :source  => :participant

  belongs_to :talk, :class_name  => :ParallelTalk,
                    :foreign_key => :talk_id,
                    :inverse_of  => :original_proposal

  # Readonly attributes
  attr_readonly :participation_id

  # Virtual attributes
  def accepted?
    !!talk_id
  end

  # Other instance methods
  def accept
    if talk.nil?
      create_talk!(:participation_id => participation_id,
                   :title            => title,
                   :abstract         => abstract)
    end
  end
end
