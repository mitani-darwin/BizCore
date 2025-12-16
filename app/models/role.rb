class Role < ApplicationRecord
  belongs_to :tenant

  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  validates :name, :key, presence: true
  validates :key, uniqueness: { scope: :tenant_id }
end
