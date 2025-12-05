class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :key, :resource, :action, :name, presence: true
  validates :key, uniqueness: true
end
