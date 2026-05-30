# 従業員セルフ画面: 経費精算申請コントローラ
class ExpenseReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_current_tenant!
  before_action :ensure_current_employee!
  before_action :set_expense_report, only: [ :show ]

  def index
    @pagy, @expense_reports = pagy(current_employee.expense_reports.order(expensed_on: :desc, id: :desc))
  end

  def new
    @expense_report = ExpenseReport.new(expensed_on: Date.current)
  end

  def create
    @expense_report = ExpenseReport.new(expense_report_params)
    @expense_report.tenant   = current_tenant
    @expense_report.employee = current_employee
    @expense_report.status   = "pending"

    if @expense_report.save
      notify_expense_report_submitted(@expense_report)
      redirect_to my_expense_reports_path, notice: "経費申請を送信しました。承認をお待ちください。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  private

  def ensure_current_tenant!
    render_not_found unless current_tenant.present?
  end

  def ensure_current_employee!
    render_not_found unless current_employee.present?
  end

  def set_expense_report
    @expense_report = current_employee.expense_reports.find_by(id: params[:id])
    render_not_found unless @expense_report
  end

  def expense_report_params
    params.require(:expense_report).permit(:expensed_on, :category, :description, :amount, :purpose, :note)
  end

  def notify_expense_report_submitted(expense_report)
    recipients = current_tenant.users
      .with_permission("admin.expense_reports.update")
      .where.not(email: nil)
    recipients.each do |recipient|
      NotificationMailer.expense_report_submitted(expense_report: expense_report, recipient: recipient).deliver_later
    end
  end
end
