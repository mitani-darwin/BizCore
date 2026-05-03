require "test_helper"

class EmployeeLocaleTest < ActiveSupport::TestCase
  test "validation messages use Japanese attribute labels" do
    tenant = Tenant.create!(
      name: "Employee Locale Tenant",
      code: "employee-locale-tenant",
      subdomain: "employee-locale",
      plan: "standard",
      status: "active",
      billing_email: "owner@employee-locale.example.com"
    )

    employee = tenant.employees.new(
      employee_code: "EMP-LOCALE-1",
      name: "日本語確認",
      status: "active",
      employment_type: "hourly",
      joined_on: Date.new(2026, 4, 1),
      base_monthly_salary: 0,
      overtime_rate_multiplier: 1.25,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10
    )

    assert_not employee.valid?
    assert_includes employee.errors.full_messages, "基本時給は時給制では必須です"
  end
end
