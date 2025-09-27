class PropertyStatus < ApplicationRecord
  has_many :properties

  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :color, presence: true
  validates :is_available, inclusion: { in: [true, false] }
  validates :active, inclusion: { in: [true, false] }
  validates :sort_order, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :available, -> { where(is_available: true, active: true) }
  scope :unavailable, -> { where(is_available: false) }
  scope :by_sort_order, -> { order(:sort_order) }
  scope :by_name, -> { order(:name) }

  def self.available_status;     find_by(name: 'available');    end
  def self.sold_status;          find_by(name: 'sold');         end
  def self.rented_status;        find_by(name: 'rented');       end
  def self.reserved_status;      find_by(name: 'reserved');     end
  def self.cancelled_status;     find_by(name: 'cancelled');    end

  def properties_count
    properties.count
  end

  def active_properties_count
    properties.joins(:user).where(users: { active: true }).count
  end

  def color_class
    "badge-#{color}"
  end

  def text_color_class
    case color
    when 'success' then 'text-success'
    when 'warning' then 'text-warning'
    when 'info' then 'text-info'
    when 'primary' then 'text-primary'
    when 'danger' then 'text-danger'
    else 'text-secondary'
    end
  end

  def background_color_class
    "bg-#{color}"
  end

  def available?
    is_available == true && active == true
  end

  def unavailable?
    !available?
  end

  def to_s
    display_name
  end

  def status_with_count
    "#{display_name} (#{properties_count})"
  end

  def final_status?
    %w[sold rented cancelled].include?(name)
  end

  def intermediate_status?
    %w[reserved].include?(name)
  end

  def initial_status?
    name == 'available'
  end

  def <=>(other)
    sort_order <=> other.sort_order
  end
end
