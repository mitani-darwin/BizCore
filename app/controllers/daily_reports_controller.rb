# 従業員セルフ画面: 日報登録・閲覧コントローラ
class DailyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_current_tenant!
  before_action :ensure_current_employee!
  before_action :set_daily_report, only: [ :show ]

  # 自分の日報一覧
  def index
    @pagy, @daily_reports = pagy(current_employee.daily_reports.includes(:site).ordered_for_admin)
  end

  # 新規日報フォーム
  def new
    @daily_report = DailyReport.new(report_date: Date.current)
    @site_options = current_tenant.sites.where(status: %w[planning active on_hold]).order(:name)
  end

  # 日報の保存
  def create
    @daily_report = DailyReport.new(daily_report_params)
    @daily_report.tenant = current_tenant
    @daily_report.employee = current_employee

    if @daily_report.save
      redirect_to my_daily_reports_path, notice: "日報を登録しました。"
    else
      @site_options = current_tenant.sites.where(status: %w[planning active on_hold]).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  # 日報詳細
  def show; end

  private

  def ensure_current_tenant!
    return if current_tenant.present?

    render_not_found
  end

  def ensure_current_employee!
    return if current_employee.present?

    render_not_found
  end

  def set_daily_report
    @daily_report = current_employee.daily_reports.includes(:site).find_by(id: params[:id])
    render_not_found and return false unless @daily_report
  end

  def daily_report_params
    params.require(:daily_report).permit(
      :site_id,
      :report_date,
      :work_content,
      :work_hours,
      :notes,
      photos: []
    )
  end
end
