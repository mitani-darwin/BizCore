module Admin
  class PermissionsController < BaseController
    before_action :set_permission, only: [:update, :destroy]

    def index
      authorize [:admin, Permission], :manage?
      @permission = Permission.new
      @permissions = policy_scope([:admin, Permission]).order(:resource, :action, :key)
    end

    def create
      authorize [:admin, Permission], :manage?
      @permission = Permission.new(permission_params)
      if @permission.save
        redirect_to admin_permissions_path, notice: "権限を作成しました。"
      else
        @permissions = policy_scope([:admin, Permission]).order(:resource, :action, :key)
        flash.now[:alert] = @permission.errors.full_messages.to_sentence
        render :index, status: :unprocessable_entity
      end
    end

    def update
      authorize [:admin, Permission], :manage?
      if @permission.update(permission_params)
        redirect_to admin_permissions_path, notice: "権限を更新しました。"
      else
        @permission = Permission.new
        @permissions = policy_scope([:admin, Permission]).order(:resource, :action, :key)
        flash.now[:alert] = @permission.errors.full_messages.to_sentence
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      authorize [:admin, Permission], :manage?
      if @permission.destroy
        redirect_to admin_permissions_path, notice: "権限を削除しました。"
      else
        redirect_to admin_permissions_path, alert: "削除に失敗しました。"
      end
    end

    private

    def set_permission
      @permission = policy_scope([:admin, Permission]).find(params[:id])
    end

    def permission_params
      params.require(:permission).permit(:key, :resource, :action, :name, :description)
    end
  end
end
