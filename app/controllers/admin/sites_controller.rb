module Admin
  # 現場・案件の管理画面コントローラ
  class SitesController < BaseController
    before_action :set_site, only: [ :show, :edit, :update, :destroy, :update_progress ]

    def index
      @filters = { q: search_keyword, status: search_status }
      query = current_tenant.sites
      query = query.where(status: @filters[:status]) if @filters[:status].present?
      query = query.where("name LIKE ? OR code LIKE ?", "%#{search_keyword}%", "%#{search_keyword}%") if @filters[:q].present?
      query = query.order(created_at: :desc, id: :desc)
      @pagy, @sites = pagy(query)
    end

    def show
      @recent_daily_reports = @site.daily_reports.includes(:employee).ordered_for_admin.limit(10)
    end

    def new
      @site = current_tenant.sites.build(status: "active", category: "construction", progress_percentage: 0)
    end

    def create
      @site = current_tenant.sites.build(site_params)

      if @site.save
        redirect_to admin_site_path(@site), notice: "現場を作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @site.update(site_params)
        redirect_to admin_site_path(@site), notice: "現場を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @site.destroy
      redirect_to admin_sites_path, notice: "現場を削除しました。"
    end

    # 進捗率とステータスのみ更新するアクション
    def update_progress
      if @site.update(progress_params)
        redirect_to admin_site_path(@site), notice: "進捗を更新しました。"
      else
        redirect_to admin_site_path(@site), alert: "進捗の更新に失敗しました。"
      end
    end

    private

    def set_site
      @site = current_tenant.sites.find_by(id: params[:id])
      render_not_found and return false unless @site
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      status = params[:status].to_s
      Site.statuses.value?(status) ? status : nil
    end

    def site_params
      params.require(:site).permit(
        :name,
        :code,
        :category,
        :status,
        :progress_percentage,
        :description,
        :address,
        :start_date,
        :end_date
      )
    end

    def progress_params
      params.require(:site).permit(:status, :progress_percentage)
    end
  end
end
