module Admin
  # 日報の管理画面コントローラ（閲覧のみ）
  class DailyReportsController < BaseController
    before_action :set_daily_report, only: [ :show ]

    def index
      @filters = {
        site_id: params[:site_id].presence,
        employee_id: params[:employee_id].presence,
        q: params[:q].to_s.strip
      }

      @daily_reports = current_tenant.daily_reports.includes(:site, :employee).ordered_for_admin
      @daily_reports = @daily_reports.where(site_id: @filters[:site_id]) if @filters[:site_id].present?
      @daily_reports = @daily_reports.where(employee_id: @filters[:employee_id]) if @filters[:employee_id].present?
      if @filters[:q].present?
        @daily_reports = @daily_reports.where("work_content LIKE ?", "%#{@filters[:q]}%")
      end

      # フィルタ用のセレクトオプション
      @site_options = current_tenant.sites.order(:name)
      @employee_options = current_tenant.employees.where(status: "active").order(:name)
    end

    def show; end

    private

    def set_daily_report
      @daily_report = current_tenant.daily_reports.includes(:site, :employee).find_by(id: params[:id])
      render_not_found and return false unless @daily_report
    end
  end
end
