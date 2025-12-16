module Admin
  class RolesController < BaseController
    before_action :set_role, only: %i[show edit update]
    before_action :set_permissions, only: %i[new create edit update]

    def index
      @roles = current_tenant.roles.includes(:permissions).order(:name)
    end

    def show; end

    def new
      @role = current_tenant.roles.build
    end

    def create
      @role = current_tenant.roles.build(role_params)
      assign_permissions(@role)

      if @role.save
        redirect_to admin_roles_path, notice: "ロールを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @role.assign_attributes(role_params)
      assign_permissions(@role)

      if @role.save
        redirect_to admin_role_path(@role), notice: "ロールを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_role
      @role = current_tenant.roles.find_by(id: params[:id])
      return if @role

      render_not_found and return false
    end

    def set_permissions
      @permissions = Permission.order(:resource, :action)
    end

    def assign_permissions(role)
      role.permission_ids = permitted_permission_ids
    end

    def permitted_permission_ids
      ids = Array(params.dig(:role, :permission_ids)).reject(&:blank?).map(&:to_i)
      @permissions ? @permissions.where(id: ids).pluck(:id) : Permission.where(id: ids).pluck(:id)
    end

    def role_params
      params.require(:role).permit(:name, :key, :description)
    end
  end
end
