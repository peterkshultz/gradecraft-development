class Metric < ActiveRecord::Base
  belongs_to :rubric, touch: true
  has_many :tiers, dependent: :destroy

  has_many :metric_badges
  has_many :badges, through: :metric_badges

  has_many :rubric_grades
  belongs_to :full_credit_tier, foreign_key: :full_credit_tier_id, class_name: "Tier", touch: true
  attr_accessible :name, :max_points, :description, :order, :rubric_id, :full_credit_tier_id
  attr_accessor :add_default_tiers

  after_initialize :set_defaults
  after_create :generate_default_tiers, if: :add_default_tiers?
  #after_save :update_full_credit, if: :add_default_tiers?

  validates :max_points, presence: true
  validates :name, presence: true, length: { maximum: 30 }
  validates :order, presence: true

  scope :ordered, lambda { order(:order) }

  def description_missing?
    description.nil? or description.blank?
  end

  include DisplayHelpers

  protected

  def add_default_tiers?
    self.add_default_tiers === true
  end

  def set_defaults
    self.add_default_tiers = true
  end

  def generate_default_tiers
    @full_credit_tier = create_full_credit_tier
    create_no_credit_tier
    #update_attributes full_credit_tier_id: @full_credit_tier[:id]
  end

  def update_full_credit
    find_and_set_full_credit_tier unless full_credit_tier
    full_credit_tier.update_attributes points: max_points
  end

  def find_and_set_full_credit_tier
    full_credit_tier = tiers.where(full_credit: true).first
    full_credit_tier ||= create_full_credit_tier
    update_attributes full_credit_tier_id: full_credit_tier[:id]
  end

  def create_full_credit_tier
    tiers.create name: "Full Credit", points: max_points, full_credit: true, durable: true, sort_order: 0
  end

  def create_no_credit_tier
    tiers.create name: "No Credit", points: 0, no_credit: true, durable: true, sort_order: 1000
  end
end
