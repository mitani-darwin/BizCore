# 従業員セルフ画面: 有給申請コントローラ
class LeaveRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_current_tenant!
  before_action :ensure_current_employee!
  before_action :set_leave_request, only: [ :show ]

  def index
    @pagy, @leave_requests = pagy(current_employee.leave_requests.order(start_date: :desc, id: :desc))
    @remaining_days = current_employee.remaining_paid_leave_days
  end

  def new
    @leave_request = LeaveRequest.new(
      start_date: Date.current,
      end_date: Date.current,
      leave_type: "paid_leave"
    )
    @remaining_days = current_employee.remaining_paid_leave_days
  end

  def create
    @leave_request = LeaveRequest.new(leave_request_params)
    @leave_request.tenant   = current_tenant
    @leave_request.employee = current_employee
    @leave_request.status   = "pending"

    if @leave_request.save
      redirect_to my_leave_requests_path, notice: "有給申請を送信しました。承認をお待ちください。"
    else
      @remaining_days = current_employee.remaining_paid_leave_days
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

  def set_leave_request
    @leave_request = current_employee.leave_requests.find_by(id: params[:id])
    render_not_found unless @leave_request
  end

  def leave_request_params
    params.require(:leave_request).permit(:leave_type, :half_day_type, :start_date, :end_date, :days_count, :reason, :note)
  end
end
