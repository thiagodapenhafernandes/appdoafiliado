class Link < ApplicationRecord
  # Relationships
  belongs_to :user

  # Validations
  validates :short_code, :original_url, presence: true
  validates :short_code, uniqueness: true
  validates :original_url, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :name, presence: true
  validates :custom_slug, uniqueness: true, allow_blank: true, 
            format: { with: /\A[a-zA-Z0-9_-]+\z/, message: "pode conter apenas letras, números, hífens e underscores" }

  # Callbacks
  before_validation :generate_short_code, on: :create
  before_validation :set_name_from_title, if: -> { name.blank? && title.present? }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_clicks, -> { order(clicks_count: :desc) }
  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  # Methods
  def short_url(request = nil)
    slug = custom_slug.presence || short_code
    base_url = if request
                 "#{request.protocol}#{request.host_with_port}"
               else
                 ENV['APP_URL'] || 'https://dev.unitymob.com.br'
               end
    "#{base_url}/go/#{slug}"
  end

  def increment_clicks!
    increment!(:clicks_count)
  end

  def self.find_by_short_code(code)
    # Primeiro tenta encontrar por custom_slug (case sensitive)
    link = find_by(custom_slug: code)
    return link if link
    
    # Se não encontrar, tenta por short_code (uppercase)
    find_by(short_code: code.upcase)
  end
  
  def expired?
    expires_at.present? && expires_at < Time.current
  end
  
  def tag_list
    return [] if tags.blank?
    tags.split(',').map(&:strip).reject(&:blank?)
  end
  
  def tag_list=(list)
    if list.is_a?(Array)
      self.tags = list.join(', ')
    else
      self.tags = list
    end
  end

  private

  def generate_short_code
    return if short_code.present?
    
    loop do
      code = SecureRandom.alphanumeric(6).upcase
      if self.class.where(short_code: code).empty?
        self.short_code = code
        break
      end
    end
  end
  
  def set_name_from_title
    self.name = title if title.present?
  end
end
