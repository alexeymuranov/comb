# encoding: UTF-8 (magic comment)

require 'digest' # hash function

require './lib/attribute_types'
require './lib/attribute_constraints'
require './lib/format_validators'

# Internationalisation
# NOTE: normally should be used only in helpers or presenters
require 'i18n'

# A custom ancestor class for all or most models
class AbstractSmarterModel < ActiveRecord::Base
  self.abstract_class = true

  include AttributeTypes
  include AttributeConstraints
end

class Conference < AbstractSmarterModel
  self.table_name = :conferences

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

class Participation < AbstractSmarterModel
  self.table_name = :participations

  # Associations
  belongs_to :participant, :class_name  => :Participant,
                           :foreign_key => :participant_id,
                           :inverse_of  => :participations

  belongs_to :conference, :class_name  => :Conference,
                          :foreign_key => :conference_id,
                          :inverse_of  => :participations

  has_many :talks, :class_name  => :Talk,
                   :foreign_key => :participation_id,
                   :dependent   => :nullify,
                   :inverse_of  => :conference_participation

  has_one :talk_proposal, :class_name  => :TalkProposal,
                          :foreign_key => :participation_id,
                          :dependent   => :destroy,
                          :inverse_of  => :participation

  has_one :conference_dinner_reservation,
          :class_name  => :ConferenceDinnerReservation,
          :foreign_key => :participation_id,
          :dependent   => :destroy,
          :inverse_of  => :participation

  accepts_nested_attributes_for :talk_proposal, :allow_destroy => true,
                                                :reject_if     => :all_blank

  # Validations
  validates :conference_id, :uniqueness => { :scope => :participant_id }

  # Readonly attributes
  attr_readonly :participant_id, :conference_id

  # Scopes
  scope :approved, where(:approved => true)
  scope :not_approved, where(:approved => false)
  scope :plenary_speakers, where(:plenary_speaker => true)
  scope :sectional_speakers, where(:speaker => true, :plenary_speaker => false)
  scope :non_speakers, where(:speaker => false)
  scope :invited_speakers, where(:invited_speaker => true)

  scope :order_by_conference, joins(:conference).merge(Conference.default_order).uniq

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

  # Virtual attributes
  def talk_proposed
    !!talk_proposal
  end

  alias_method :talk_proposed?, :talk_proposed

  # The following method is defined in the custom `AttributeTypes` module
  add_attribute_types :talk_proposed  => :boolean,
                      :talk_proposed? => :boolean
end

class Participant < AbstractSmarterModel
  self.table_name = :participants

  # Associations
  has_many :participations, :class_name  => :Participation,
                            :foreign_key => :participant_id,
                            :dependent   => :destroy,
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
                            :inverse_of  => :participant,
                            :autosave    => true

  has_many :hotels, :through => :accommodations,
                    :source  => :hotel

  has_many :conference_dinner_reservations,
           :through => :participations,
           :source  => :conference_dinner_reservation

  accepts_nested_attributes_for :participations, :allow_destroy => true

  accepts_nested_attributes_for :accommodations, :allow_destroy => true

  # Validations
  validates :first_name, :last_name, :email, :presence => true

  validates :first_name, :last_name, :length => { :maximum => 32 }

  validates :name_title, :length    => { :maximum   => 16 },
                         :allow_nil => true

  validates :email, :email_format => true

  validates :phone, :telephone_format => true,
                    :allow_nil => true

  validates :gender,
            :inclusion => { :in => ['female', 'male', :female, :male] },
            :allow_nil => true

  validates :academic_position,
            :inclusion => [ "graduate student",
                            "doctorant(e)",
                            "recent PhD",
                            "docteur ès mathématiques récemment diplômé(e)",
                            "postdoc",
                            "post-doctorant(e)",
                            "professor/faculty",
                            "enseignant(e)-chercheur(se)",
                            "other (explain in the comments)",
                            "autre (à préciser dans les remarques)" ]

  # validates :first_name, :uniqueness => { :scope         => :last_name,
  #                                         :case_sesitive => false }

  validates :email, :uniqueness => true

  # Validaton of assocaitions
  validates :participations, :presence => true

  # Scopes
  scope :default_order, order("UPPER(#{ table_name }.last_name) ASC").
                          order("UPPER(#{ table_name }.first_name) ASC")

  scope :approved, joins(:participations).merge(Participation.approved).uniq

  scope :not_all_participations_approved,
        joins(:participations).merge(Participation.not_approved).uniq

  # Virtual attributes
  def full_name
    "#{ first_name } #{ last_name }"
  end

  def full_name_with_affiliation
    affiliation ? "#{ full_name } (#{ affiliation })" : full_name
  end

  def full_name_with_affiliation_and_position
    [ full_name,
      lambda{|x| "(#{ x })" unless x.empty? }.
        call([affiliation, academic_position].compact.join(', '))
    ].join(' ')
  end

  def new_pin; @new_pin end

  def approved
    participations.approved.any?
  end

  alias_method :approved?, :approved

  def first_arrival_date
    first_arrival_date = nil
    participations.each do |participation|
      if arrival_date = participation.arrival_date
        if first_arrival_date.nil? || first_arrival_date > arrival_date
          first_arrival_date = arrival_date
        end
      end
    end
    first_arrival_date
  end

  def last_departure_date
    last_departure_date = nil
    participations.each do |participation|
      if departure_date = participation.departure_date
        if last_departure_date.nil? || last_departure_date < departure_date
          last_departure_date = departure_date
        end
      end
    end
    last_departure_date
  end

  # The following method is defined in the custom `AttributeTypes` module
  add_attribute_types :approved  => :boolean,
                      :approved? => :boolean

  # def approved=(bool)
  #   participations.each do |p| p.approved = bool end
  # end

  # CoMB related
  def co_m_b_participation
    @co_m_b_conf_id ||= Conference.co_m_b_conf.id
    # NOTE: if participations have not been saved, `where` will not find
    # anything.
    participations.where(:conference_id => @co_m_b_conf_id).first ||
      participations.find{|p| p.conference_id ==  @co_m_b_conf_id }
  end

  def co_m_b_committee_comments
    co_m_b_participation.committee_comments if co_m_b_participation
  end

  def co_m_b_talk_proposal
    co_m_b_participation.talk_proposal if co_m_b_participation
  end

  # Public instance methods
  def approve!
    participations.each do |p| p.approved = true end
  end

  def disapprove!
    participations.each do |p| p.approved = false end
  end

  def generate_pin
    @new_pin = Digest::SHA2.hexdigest(rand.to_s)[0..3]
    self.pin_code_hash = Digest::SHA2.base64digest(@new_pin)
    @new_pin
  end

  def accept_pin?(pin)
    Digest::SHA2.base64digest(pin) == pin_code_hash
  end
end

class Talk < AbstractSmarterModel
  self.table_name = :talks
  self.inheritance_column = :type

  # Associations
  belongs_to :conference_participation, :class_name  => :Participation,
                                        :foreign_key => :participation_id,
                                        :inverse_of  => :talks

  has_one :conference, :through => :conference_participation,
                       :source  => :conference

  has_one :speaker, :through => :conference_participation,
                    :source  => :participant

  has_one :original_proposal, :class_name  => :TalkProposal,
                              :foreign_key => :talk_id,
                              :dependent   => :nullify,
                              :inverse_of  => :talk

  # Validations
  validates :type, :participation_id, :title, :presence => true

  validates :type, :inclusion => { :in => %w[PlenaryTalk ParallelTalk] }

  # Readonly attributes
  attr_readonly :participation_id

  # Scopes
  scope :default_order, order("UPPER(#{ table_name }.type) DESC").joins(:speaker).merge(Participant.default_order).uniq

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

class Hotel < AbstractSmarterModel
  self.table_name = :hotels

  # Associations
  has_many :accommodations, :class_name  => :Accommodation,
                            :foreign_key => :hotel_id,
                            :inverse_of  => :hotel

  has_many :participants, :through => :accommodations,
                          :source  => :participant

  # Validations
  validates :name, :presence => true

  # Scopes
  scope :default_order, order("UPPER(#{ table_name }.name) ASC")
end

class Accommodation < AbstractSmarterModel
  self.table_name = :accommodations

  # Associations
  belongs_to :participant, :class_name  => :Participant,
                           :foreign_key => :participant_id,
                           :inverse_of  => :accommodations

  belongs_to :hotel, :class_name  => :Hotel,
                     :foreign_key => :hotel_id,
                     :inverse_of  => :accommodations

  # Validations
  validates :participant_id, :hotel_id, :presence => true

  # Readonly attributes
  attr_readonly :participant_id, :hotel_id

  # Scopes
  scope :default_order, order("#{ table_name }.arrival_date ASC")
end

class ConferenceDinnerReservation < AbstractSmarterModel
  self.table_name = :conference_dinner_reservations

  # Associations
  belongs_to :participation, :class_name  => :Participation,
                             :foreign_key => :participation_id,
                             :inverse_of  => :conference_dinner_reservation

  # Readonly attributes
  attr_readonly :participatioin_id
end

class TalkProposal < AbstractSmarterModel
  self.table_name = :talk_proposals

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
      create_talk! :participation_id => participation_id,
                   :title            => title,
                   :abstract         => abstract
    end
  end
end
