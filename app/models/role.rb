class Role < ApplicationRecord
  belongs_to :tenant

  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  scope :built_in, -> { where(built_in: true) }
  scope :custom, -> { where(built_in: false) }

  validates :name, :key, presence: true
  validates :key, uniqueness: { scope: :tenant_id }

  def editable?
    !built_in?
  end

  def deletable?
    !built_in?
  end
end
