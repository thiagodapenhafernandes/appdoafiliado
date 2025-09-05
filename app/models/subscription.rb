class Subscription < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :plan
  has_one :user_with_active_subscription, 
          -> { where(users: { subscription_id: :id }) },
          class_name: 'User',
          foreign_key: :subscription_id

  # Validations
  validates :status, presence: true
  validates :stripe_subscription_id, uniqueness: true, allow_nil: true

  # Enums
  enum status: {
    active: 'active',
    canceled: 'canceled',
    past_due: 'past_due',
    incomplete: 'incomplete',
    trialing: 'trialing'
  }

  # Scopes
  scope :active, -> { where(status: ['active', 'trialing']) }
  scope :active_subscriptions, -> { where(status: ['active', 'trialing']) }

  # Methods
  def active?
    (status == 'active' || status == 'trialing') && current_period_end&.future?
  end

  def expired?
    !active?
  end

  def on_trial?
    status == 'trialing' && trial_ends_at&.future?
  end

  def days_until_renewal
    return 0 unless current_period_end
    ((current_period_end - Time.current) / 1.day).to_i
  end
end
