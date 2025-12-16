module Admin
  class PermissionsController < BaseController
    before_action :set_permission, only: [:update, :destroy]

    def index
      @permission = Permission.new
      @permissions = Permission.order(:resource, :action, :key)
    end

    def create
      @permission = Permission.new(permission_params)
      if @permission.save
        redirect_to admin_permissions_path, notice: "権限を作成しました。"
      else
        @permissions = Permission.order(:resource, :action, :key)
        flash.now[:alert] = @permission.errors.full_messages.to_sentence
        render :index, status: :unprocessable_entity
      end
    end

    def update
      if @permission.update(permission_params)
        redirect_to admin_permissions_path, notice: "権限を更新しました。"
      else
        @permission = Permission.new
        @permissions = Permission.order(:resource, :action, :key)
        flash.now[:alert] = @permission.errors.full_messages.to_sentence
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      if @permission.destroy
        redirect_to admin_permissions_path, notice: "権限を削除しました。"
      else
        redirect_to admin_permissions_path, alert: "削除に失敗しました。"
      end
    end

    private

    def set_permission
      @permission = Permission.find_by(id: params[:id])
      render_not_found and return false unless @permission
    end

    def permission_params
      params.require(:permission).permit(:key, :resource, :action, :name, :description)
    end
  end
end
