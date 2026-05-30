# 社内向け通知メーラー。
# 有給申請・承認・却下、経費精算申請・承認・却下を対象ユーザーに送信する。
# deliver_later で非同期送信し、リクエストをブロックしない。
class NotificationMailer < ApplicationMailer
  # 有給申請が提出されたことを承認権限保有ユーザーに通知する。
  def leave_request_submitted(leave_request:, recipient:)
    @leave_request = leave_request
    @employee      = leave_request.employee
    @recipient     = recipient

    mail(
      to:      recipient.email,
      subject: "[#{@employee.tenant.name}] 有給申請が届いています - #{@employee.name}"
    )
  end

  # 有給申請の承認・却下結果を申請した従業員のユーザーに通知する。
  def leave_request_decision(leave_request:, recipient:)
    @leave_request = leave_request
    @employee      = leave_request.employee
    @recipient     = recipient

    subject_status = leave_request.status_approved? ? "承認" : "却下"
    mail(
      to:      recipient.email,
      subject: "[#{@employee.tenant.name}] 有給申請が#{subject_status}されました"
    )
  end

  # 経費精算申請が提出されたことを承認権限保有ユーザーに通知する。
  def expense_report_submitted(expense_report:, recipient:)
    @expense_report = expense_report
    @employee       = expense_report.employee
    @recipient      = recipient

    mail(
      to:      recipient.email,
      subject: "[#{@employee.tenant.name}] 経費精算申請が届いています - #{@employee.name}"
    )
  end

  # 経費精算の承認・却下結果を申請した従業員のユーザーに通知する。
  def expense_report_decision(expense_report:, recipient:)
    @expense_report = expense_report
    @employee       = expense_report.employee
    @recipient      = recipient

    subject_status = expense_report.status_approved? ? "承認" : "却下"
    mail(
      to:      recipient.email,
      subject: "[#{@employee.tenant.name}] 経費精算申請が#{subject_status}されました"
    )
  end
end
