require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "通知テストテナント",
      code: "notif-test",
      subdomain: "notif-test",
      plan: "standard",
      status: "active",
      billing_email: "billing@notif-test.example.com"
    )

    @employee = @tenant.employees.create!(
      employee_code: "EMP-NTF-1",
      name: "申請者",
      status: "active",
      employment_type: "hourly",
      joined_on: Date.new(2026, 4, 1),
      base_hourly_wage: 1_500,
      base_monthly_salary: 0,
      overtime_rate_multiplier: 1.25,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10
    )

    @employee_user = User.create!(
      tenant: @tenant,
      employee: @employee,
      name: "申請者ユーザー",
      email: "applicant@notif-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    @admin_user = User.create!(
      tenant: @tenant,
      name: "管理者",
      email: "admin@notif-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      is_owner: true
    )

    @leave_request = @tenant.leave_requests.create!(
      employee: @employee,
      leave_type: "paid_leave",
      start_date: Date.new(2026, 7, 1),
      end_date: Date.new(2026, 7, 3),
      days_count: 3,
      status: "pending",
      reason: "夏季休暇"
    )

    @expense_report = @tenant.expense_reports.create!(
      employee: @employee,
      expensed_on: Date.new(2026, 7, 1),
      category: "transportation",
      description: "出張交通費",
      amount: 5_000,
      status: "pending"
    )
  end

  test "leave_request_submitted: 件名・宛先・本文が正しい" do
    mail = NotificationMailer.leave_request_submitted(leave_request: @leave_request, recipient: @admin_user)

    assert_equal "[通知テストテナント] 有給申請が届いています - 申請者", mail.subject
    assert_equal [ "admin@notif-test.example.com" ], mail.to
    html_body = mail.parts.find { |p| p.content_type.include?("text/html") }&.decoded
    assert_match "申請者", html_body
    assert_match "2026/07/01", html_body
  end

  test "leave_request_submitted: テキスト・HTML 両方のパートが存在する" do
    mail = NotificationMailer.leave_request_submitted(leave_request: @leave_request, recipient: @admin_user)

    assert mail.multipart?
    assert mail.parts.any? { |p| p.content_type.include?("text/plain") }
    assert mail.parts.any? { |p| p.content_type.include?("text/html") }
  end

  test "leave_request_decision (承認): 件名・本文に承認が含まれる" do
    @leave_request.update!(status: "approved")
    mail = NotificationMailer.leave_request_decision(leave_request: @leave_request, recipient: @employee_user)

    assert_equal "[通知テストテナント] 有給申請が承認されました", mail.subject
    assert_equal [ "applicant@notif-test.example.com" ], mail.to
  end

  test "leave_request_decision (却下): 件名に却下が含まれる" do
    @leave_request.update!(status: "rejected")
    mail = NotificationMailer.leave_request_decision(leave_request: @leave_request, recipient: @employee_user)

    assert_equal "[通知テストテナント] 有給申請が却下されました", mail.subject
  end

  test "expense_report_submitted: 件名・宛先・本文が正しい" do
    mail = NotificationMailer.expense_report_submitted(expense_report: @expense_report, recipient: @admin_user)

    assert_equal "[通知テストテナント] 経費精算申請が届いています - 申請者", mail.subject
    assert_equal [ "admin@notif-test.example.com" ], mail.to
    text_body = mail.parts.find { |p| p.content_type.include?("text/plain") }&.decoded
    assert_match "5,000", text_body
  end

  test "expense_report_decision (承認): 件名に承認が含まれる" do
    @expense_report.update!(status: "approved")
    mail = NotificationMailer.expense_report_decision(expense_report: @expense_report, recipient: @employee_user)

    assert_equal "[通知テストテナント] 経費精算申請が承認されました", mail.subject
    assert_equal [ "applicant@notif-test.example.com" ], mail.to
  end

  test "expense_report_decision (却下): 件名に却下が含まれる" do
    @expense_report.update!(status: "rejected")
    mail = NotificationMailer.expense_report_decision(expense_report: @expense_report, recipient: @employee_user)

    assert_equal "[通知テストテナント] 経費精算申請が却下されました", mail.subject
  end
end
