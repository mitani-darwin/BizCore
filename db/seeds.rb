require_relative "seeds/permissions/admin_permissions"

# 実行順序: permissions -> roles -> users(assignments)
DEFAULT_PASSWORD = ENV.fetch("DEFAULT_PASSWORD", "ChangeMe123!")

def ensure_tenant(attrs)
  Tenant.find_or_create_by!(code: attrs.fetch(:code)) do |t|
    t.name = attrs.fetch(:name)
    t.subdomain = attrs.fetch(:subdomain)
    t.plan = attrs[:plan] || "standard"
    t.status = attrs[:status] || "active"
    t.billing_email = attrs[:billing_email] || "owner@#{attrs[:code]}.example.com"
  end
end

def ensure_roles(tenant, permission_records)
  all_ids = permission_records.values.map(&:id)
  read_ids = permission_records.values.select { |p| p.action == "read" }.map(&:id)

  owner = tenant.roles.find_or_create_by!(key: "owner") do |r|
    r.name = "オーナー"
    r.description = "全権限"
    r.built_in = true
  end
  admin = tenant.roles.find_or_create_by!(key: "admin") do |r|
    r.name = "管理者"
    r.description = "全権限"
    r.built_in = true
  end
  manager = tenant.roles.find_or_create_by!(key: "manager") do |r|
    r.name = "マネージャー"
    r.description = "閲覧 + ユーザ/ロール編集"
    r.built_in = false
  end
  viewer = tenant.roles.find_or_create_by!(key: "viewer") do |r|
    r.name = "閲覧者"
    r.description = "閲覧のみ"
    r.built_in = false
  end

  owner.permission_ids = all_ids
  admin.permission_ids = all_ids
  manager.permission_ids = (read_ids + permission_records.values.select { |p| %w[users roles].include?(p.resource) }.map(&:id)).uniq
  viewer.permission_ids = read_ids

  { owner: owner, admin: admin, manager: manager, viewer: viewer }
end

def ensure_user(tenant:, email:, name:, roles: [], owner_flag: false)
  user = User.find_or_initialize_by(email: email)
  user.tenant = tenant
  user.name = name
  user.is_owner = owner_flag
  user.password = DEFAULT_PASSWORD
  user.password_confirmation = DEFAULT_PASSWORD
  user.locale = "ja"
  user.time_zone = "Asia/Tokyo"
  user.role_ids = roles.map(&:id) if roles.present?
  user.save!

  roles.each do |role|
    Assignment.find_or_create_by!(tenant:, user:, role:)
  end

  user
end

def ensure_employee(tenant:, employee_code:, name:, email:, tel:, employment_type:, base_hourly_wage:, base_monthly_salary:, standard_daily_minutes:, default_break_minutes:, paid_leave_granted_days:, joined_on:, note: nil)
  employee = tenant.employees.find_or_initialize_by(employee_code: employee_code)
  employee.name = name
  employee.email = email
  employee.tel = tel
  employee.status = "active"
  employee.employment_type = employment_type
  employee.base_hourly_wage = base_hourly_wage
  employee.base_monthly_salary = base_monthly_salary
  employee.standard_daily_minutes = standard_daily_minutes
  employee.default_break_minutes = default_break_minutes
  employee.paid_leave_granted_days = paid_leave_granted_days
  employee.joined_on = joined_on
  employee.overtime_rate_multiplier = 1.25
  employee.note = note
  employee.save!
  employee
end

def ensure_employee_user(tenant:, employee:, email:, name:)
  user = User.find_or_initialize_by(email: email)
  user.tenant = tenant
  user.employee = employee
  user.name = name
  user.is_owner = false
  user.password = DEFAULT_PASSWORD
  user.password_confirmation = DEFAULT_PASSWORD
  user.locale = "ja"
  user.time_zone = "Asia/Tokyo"
  user.role_ids = []
  user.save!
  Assignment.where(tenant:, user:).delete_all
  user
end

def ensure_work_shift(tenant:, employee:, work_date:, start_time:, end_time:, break_minutes:, status: "scheduled", note: nil)
  work_shift = tenant.work_shifts.find_or_initialize_by(employee:, work_date:)
  work_shift.start_time = start_time
  work_shift.end_time = end_time
  work_shift.break_minutes = break_minutes
  work_shift.status = status
  work_shift.note = note
  work_shift.save!
  work_shift
end

def ensure_attendance_record(tenant:, employee:, work_date:, clock_in_at:, clock_out_at:, break_minutes:, note: nil)
  attendance_record = tenant.attendance_records.find_or_initialize_by(employee:, work_date:)
  attendance_record.clock_in_at = clock_in_at
  attendance_record.clock_out_at = clock_out_at
  attendance_record.break_minutes = break_minutes
  attendance_record.note = note
  attendance_record.save!
  attendance_record
end

permissions = Seeds::Permissions::Admin.call

tenants = [
  { code: "darwin", name: "Darwin HQ", subdomain: "darwin", plan: "enterprise", billing_email: "owner@darwin.example.com" },
  { code: "acme", name: "Acme Corp", subdomain: "acme", plan: "standard", billing_email: "owner@acme.example.com" }
]

tenants.each do |attrs|
  tenant = ensure_tenant(attrs)
  roles = ensure_roles(tenant, permissions)

  owner_user = ensure_user(
    tenant: tenant,
    email: attrs[:billing_email],
    name: "#{attrs[:name]} オーナー",
    roles: [roles[:owner]],
    owner_flag: true
  )

  ensure_user(
    tenant: tenant,
    email: "admin@#{tenant.code}.example.com",
    name: "#{tenant.name} 管理者",
    roles: [roles[:admin]],
    owner_flag: false
  )

  ensure_user(
    tenant: tenant,
    email: "manager@#{tenant.code}.example.com",
    name: "#{tenant.name} マネージャー",
    roles: [roles[:manager]],
    owner_flag: false
  )

  ensure_user(
    tenant: tenant,
    email: "viewer@#{tenant.code}.example.com",
    name: "#{tenant.name} 閲覧者",
    roles: [roles[:viewer]],
    owner_flag: false
  )

  employees = [
    {
      employee_code: "EMP-001",
      name: "#{tenant.name} 山田",
      email: "employee1@#{tenant.code}.example.com",
      tel: "03-0000-0001",
      employment_type: "hourly",
      base_hourly_wage: 1200,
      base_monthly_salary: 0,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10,
      joined_on: Date.current.prev_month.beginning_of_month,
      note: "セルフ打刻確認用の時給社員"
    },
    {
      employee_code: "EMP-002",
      name: "#{tenant.name} 佐藤",
      email: "employee2@#{tenant.code}.example.com",
      tel: "03-0000-0002",
      employment_type: "salaried",
      base_hourly_wage: 0,
      base_monthly_salary: 320_000,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 12,
      joined_on: Date.current.prev_month.beginning_of_month,
      note: "セルフ打刻確認用の月給社員"
    }
  ]

  employees.each do |employee_attrs|
    employee = ensure_employee(tenant:, **employee_attrs)
    ensure_employee_user(
      tenant: tenant,
      employee: employee,
      email: employee_attrs.fetch(:email),
      name: "#{employee.name} ログイン"
    )

    ensure_work_shift(
      tenant: tenant,
      employee: employee,
      work_date: Date.current,
      start_time: "09:00",
      end_time: "18:00",
      break_minutes: employee.default_break_minutes,
      status: "scheduled",
      note: "本日の通常シフト"
    )
    ensure_work_shift(
      tenant: tenant,
      employee: employee,
      work_date: Date.current.yesterday,
      start_time: "09:00",
      end_time: "18:00",
      break_minutes: employee.default_break_minutes,
      status: "completed",
      note: "前日の通常シフト"
    )
    ensure_attendance_record(
      tenant: tenant,
      employee: employee,
      work_date: Date.current.yesterday,
      clock_in_at: Time.zone.parse("#{Date.current.yesterday} 09:00"),
      clock_out_at: Time.zone.parse("#{Date.current.yesterday} 18:15"),
      break_minutes: employee.default_break_minutes,
      note: "seed作成の前日勤怠"
    )
  end
end

puts "Seeded tenants, roles, permissions, and sample users. Default password: #{DEFAULT_PASSWORD}"
puts "Seeded employee login users: employee1@darwin.example.com, employee2@darwin.example.com, employee1@acme.example.com, employee2@acme.example.com"
