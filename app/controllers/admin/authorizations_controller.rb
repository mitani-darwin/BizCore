module Admin
  class AuthorizationsController < ApplicationController
    helper_method :locked_role?

    before_action :authorize_page
    before_action :load_roles_and_permissions

    def show
    end

    def update
      ActiveRecord::Base.transaction do
        @roles.each do |role|
          next if locked_role?(role)

          role.permission_ids = submitted_permission_ids_for(role)
        end
      end

      redirect_to admin_authorization_path, notice: "権限設定を更新しました。"
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "権限の保存に失敗しました。#{e.record.errors.full_messages.to_sentence}"
      render :show, status: :unprocessable_entity
    end

    private

    def authorize_page
      authorize [:admin, :authorization], :manage?
    end

    def load_roles_and_permissions
      @roles = policy_scope([:admin, Role]).includes(:permissions).order(:id)
      @permissions = Permission.order(:resource, :action, :id)
      @permissions_by_resource = @permissions.group_by(&:resource)
      @permission_ids = @permissions.map(&:id)
    end

    def submitted_permission_ids_for(role)
      raw_ids = role_permission_params.dig(role.id.to_s, "permission_ids") || []
      Array(raw_ids).map(&:to_i) & @permission_ids
    end

    def role_permission_params
      params.fetch(:role_permissions, {}).to_unsafe_h
    end

    def locked_role?(role)
      role.built_in? && %w[owner].include?(role.key)
    end
  end
end
