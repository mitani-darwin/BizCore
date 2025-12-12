module Admin
  class UsersController < ApplicationController
    before_action :set_tenant_options, only: [:index, :new, :create]
    before_action :set_selected_tenant, only: [:new, :create]
    before_action :set_role_options, only: [:new, :create]

    def index
      @tenant_search_name = params[:tenant_name].to_s.strip
      @tenant_search_code = params[:tenant_code].to_s.strip
      @tenant_search_subdomain = params[:tenant_subdomain].to_s.strip
      @selected_tenant = detect_selected_tenant
      @selected_tenant_id = @selected_tenant&.id
      @users = User.includes(:tenant, :roles).order(updated_at: :desc)
      @users = filter_by_tenant(@users)
    end

    def new
      @user = User.new(
        time_zone: "Asia/Tokyo",
        locale: "ja",
        tenant_id: params[:tenant_id]
      )
    end

    def create
      @user = User.new(user_params)
      assign_roles(@user)

      if @user.save
        redirect_to admin_users_path, notice: "ユーザを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_tenant_options
      @tenant_options = Tenant.order(:name).limit(100)
    end

    def filter_by_tenant(scope)
      return scope if @tenant_search_name.blank? && @tenant_search_code.blank? && @tenant_search_subdomain.blank?

      tenant_table = Tenant.arel_table
      scoped = scope.joins(:tenant)
      scoped = scoped.where(tenant_table[:name].eq(@tenant_search_name)) if @tenant_search_name.present?
      scoped = scoped.where(tenant_table[:code].eq(@tenant_search_code)) if @tenant_search_code.present?
      scoped = scoped.where(tenant_table[:subdomain].eq(@tenant_search_subdomain)) if @tenant_search_subdomain.present?
      scoped
    end

    def detect_selected_tenant
      return nil if @tenant_search_name.blank? && @tenant_search_code.blank? && @tenant_search_subdomain.blank?

      scope = Tenant.all
      scope = scope.where(name: @tenant_search_name) if @tenant_search_name.present?
      scope = scope.where(code: @tenant_search_code) if @tenant_search_code.present?
      scope = scope.where(subdomain: @tenant_search_subdomain) if @tenant_search_subdomain.present?
      scope.first
    end

    def set_selected_tenant
      tenant_id = params[:tenant_id].presence || @user&.tenant_id
      @selected_tenant = tenant_id.present? ? Tenant.find_by(id: tenant_id) : nil
      @user.tenant_id ||= @selected_tenant&.id if defined?(@user) && @user.present?
    end

    def set_role_options
      @role_options = @selected_tenant.present? ? @selected_tenant.roles.order(:id) : Role.none
    end

    def assign_roles(user)
      return if @selected_tenant.blank?

      selected_ids = role_ids_param
      return if selected_ids.empty?

      allowed_ids = @role_options.pluck(:id)
      user.role_ids = selected_ids & allowed_ids
    end

    def role_ids_param
      Array(params.dig(:user, :role_ids)).reject(&:blank?).map(&:to_i)
    end

    def user_params
      params.require(:user).permit(
        :tenant_id,
        :name,
        :email,
        :password,
        :password_confirmation,
        :is_owner,
        :locale,
        :time_zone
      )
    end
  end
end
