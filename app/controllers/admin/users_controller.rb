module Admin
  class UsersController < ApplicationController
    before_action :set_tenant_options, only: [:index, :new, :create]
    before_action :set_user, only: [:edit, :update, :destroy]
    before_action :set_selected_tenant, only: [:new, :create, :edit, :update, :destroy]
    before_action :set_role_options, only: [:new, :create, :edit, :update]

    def index
      authorize User, :manage?

      @selected_tenant = current_tenant
      @tenant_search_name = @selected_tenant&.name.to_s
      @tenant_search_code = @selected_tenant&.code.to_s
      @tenant_search_subdomain = @selected_tenant&.subdomain.to_s
      @selected_tenant_id = @selected_tenant&.id
      @users = policy_scope(User).includes(:tenant, :roles).order(id: :asc)
    end

    def new
      authorize User, :manage?

      @user = User.new(
        time_zone: "Asia/Tokyo",
        locale: "ja",
        tenant_id: current_tenant&.id
      )
    end

    def edit
      authorize @user, :manage?
    end

    def create
      authorize User, :manage?

      @user = User.new(user_params.merge(tenant: current_tenant))
      @user.initial_flag = true if @user.respond_to?(:initial_flag=)
      assign_roles(@user)

      if @user.save
        redirect_to admin_users_path(tenant_id: @user.tenant_id), notice: "ユーザを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize @user, :manage?

      @user.assign_attributes(user_params)
      assign_roles(@user)

      if @user.save
        redirect_to admin_users_path(tenant_id: @user.tenant_id), notice: "ユーザを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @user, :manage?

      tenant_id = @user.tenant_id
      if @user.destroy
        redirect_to admin_users_path(tenant_id: tenant_id), notice: "ユーザを削除しました。"
      else
        redirect_to admin_users_path(tenant_id: tenant_id), alert: "ユーザの削除に失敗しました。"
      end
    end

    private

    def set_user
      @user = policy_scope(User).find(params[:id])
    end

    def set_tenant_options
      @tenant_options = [current_tenant].compact
    end

    def set_selected_tenant
      @selected_tenant = current_tenant
      @user.tenant_id ||= @selected_tenant.id if defined?(@user) && @user.present? && @selected_tenant.present?
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
        :name,
        :email,
        :line_id,
        :password,
        :password_confirmation,
        :is_owner,
        :locale,
        :time_zone,
        role_ids: []
      )
    end
  end
end
