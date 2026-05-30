module Admin
  # 休暇申請の CRUD・承認・却下を管理する。
  # approve / reject は LeaveRequest モデルのメソッドを直接呼び出す。
  class LeaveRequestsController < BaseController
    before_action :set_leave_request, only: [ :show, :edit, :update, :approve, :reject ]
    before_action :set_employee_options, only: [ :index, :new, :create, :edit, :update ]

    def index
      @current_month = selected_month
      @filters = {
        month: @current_month.strftime("%Y-%m"),
        employee_id: search_employee_id,
        status: search_status
      }
      query = current_tenant.leave_requests
                            .includes(:employee)
                            .for_month(@current_month)
                            .with_employee(search_employee_id)
                            .with_status(search_status)
                            .ordered_for_admin
      @leave_summary = {
        count: query.size,
        pending_count: query.count(&:status_pending?),
        approved_days: query.select(&:status_approved?).sum { |leave_request| leave_request.days_within(@current_month.beginning_of_month..@current_month.end_of_month) }
      }
      @pagy, @leave_requests = pagy(query)
    end

    def show; end

    def new
      @leave_request = current_tenant.leave_requests.build(default_leave_request_attributes)
    end

    def create
      @leave_request = current_tenant.leave_requests.build(leave_request_params)

      if @leave_request.save
        notify_leave_request_submitted(@leave_request)
        redirect_to admin_leave_request_path(@leave_request), notice: "有給申請を作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @leave_request.update(leave_request_params)
        redirect_to admin_leave_request_path(@leave_request), notice: "有給申請を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      @leave_request.approve!
      audit!(action_key: required_permission_key, auditable: @leave_request, metadata: { status: "approved" })
      notify_leave_request_decision(@leave_request)
      redirect_to admin_leave_request_path(@leave_request), notice: "有給申請を承認しました。"
    rescue StandardError => e
      redirect_to admin_leave_request_path(@leave_request), alert: "承認に失敗しました: #{e.message}"
    end

    def reject
      @leave_request.reject!
      audit!(action_key: required_permission_key, auditable: @leave_request, metadata: { status: "rejected" })
      notify_leave_request_decision(@leave_request)
      redirect_to admin_leave_request_path(@leave_request), notice: "有給申請を却下しました。"
    rescue StandardError => e
      redirect_to admin_leave_request_path(@leave_request), alert: "却下に失敗しました: #{e.message}"
    end

    private

    def set_leave_request
      @leave_request = current_tenant.leave_requests.includes(:employee).find_by(id: params[:id])
      return if @leave_request

      render_not_found and return false
    end

    def set_employee_options
      @employee_options = current_tenant.employees.ordered_for_admin
    end

    def selected_month
      value = params[:month].presence || Date.current.strftime("%Y-%m")
      Date.strptime(value, "%Y-%m")
    rescue ArgumentError
      Date.current.beginning_of_month
    end

    def search_employee_id
      employee_id = params[:employee_id].to_i
      employee_id.positive? ? employee_id : nil
    end

    def search_status
      status = params[:status].to_s
      LeaveRequest.statuses.value?(status) ? status : nil
    end

    def default_leave_request_attributes
      {
        employee_id: params[:employee_id],
        start_date: Date.current,
        end_date: Date.current,
        leave_type: "paid_leave",
        days_count: 1
      }
    end

    def leave_request_params
      params.require(:leave_request).permit(
        :employee_id,
        :leave_type,
        :half_day_type,
        :start_date,
        :end_date,
        :days_count,
        :reason,
        :note
      )
    end

    # 有給申請提出を承認権限保有者全員に通知する。
    def notify_leave_request_submitted(leave_request)
      recipients = current_tenant.users
        .with_permission("admin.leave_requests.update")
        .where.not(email: nil)
      recipients.each do |recipient|
        NotificationMailer.leave_request_submitted(leave_request: leave_request, recipient: recipient).deliver_later
      end
    end

    # 有給申請の決定結果を申請した従業員のユーザーに通知する。
    def notify_leave_request_decision(leave_request)
      recipient = leave_request.employee&.user
      return if recipient.nil? || recipient.email.blank?

      NotificationMailer.leave_request_decision(leave_request: leave_request, recipient: recipient).deliver_later
    end
  end
end
