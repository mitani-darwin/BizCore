module Admin
  # 現場日報の CRUD を管理する。
  class DailyReportsController < BaseController
    before_action :set_daily_report, only: [ :show, :edit, :update, :destroy ]

    def index
      @filters = {
        site_id: params[:site_id].presence,
        employee_id: params[:employee_id].presence,
        q: params[:q].to_s.strip
      }

      query = current_tenant.daily_reports.includes(:site, :employee).ordered_for_admin
      query = query.where(site_id: @filters[:site_id]) if @filters[:site_id].present?
      query = query.where(employee_id: @filters[:employee_id]) if @filters[:employee_id].present?
      if @filters[:q].present?
        query = query.where("work_content LIKE ?", "%#{@filters[:q]}%")
      end
      @pagy, @daily_reports = pagy(query)

      @site_options = current_tenant.sites.order(:name)
      @employee_options = current_tenant.employees.where(status: "active").order(:name)
    end

    def show; end

    def new
      @daily_report = current_tenant.daily_reports.build(report_date: Date.current)
      load_form_options
    end

    def create
      @daily_report = current_tenant.daily_reports.build(daily_report_params)

      if @daily_report.save
        redirect_to admin_daily_report_path(@daily_report), notice: "日報を登録しました。"
      else
        load_form_options
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_options
    end

    def update
      if @daily_report.update(daily_report_params)
        redirect_to admin_daily_report_path(@daily_report), notice: "日報を更新しました。"
      else
        load_form_options
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @daily_report.destroy
      redirect_to admin_daily_reports_path, notice: "日報を削除しました。"
    end

    private

    def set_daily_report
      @daily_report = current_tenant.daily_reports.includes(:site, :employee).find_by(id: params[:id])
      render_not_found and return false unless @daily_report
    end

    def load_form_options
      @site_options = current_tenant.sites.where(status: %w[planning active on_hold]).order(:name)
      @employee_options = current_tenant.employees.where(status: "active").order(:name)
    end

    def daily_report_params
      params.require(:daily_report).permit(
        :employee_id,
        :site_id,
        :report_date,
        :work_content,
        :work_hours,
        :notes,
        photos: []
      )
    end
  end
end
