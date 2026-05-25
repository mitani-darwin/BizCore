class AddHalfDayTypeToLeaveRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :leave_requests, :half_day_type, :string, default: "none", null: false
  end
end
