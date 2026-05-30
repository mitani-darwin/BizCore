module Admin
  # ユーザーへのロール付与・剥奪を管理する。一覧表示と create/destroy のみ実装する。
  class AssignmentsController < BaseController
    before_action :load_users_and_roles

    def index
    end

    def create
      ActiveRecord::Base.transaction do
        submitted = assignment_params
        allowed_role_ids = @roles.pluck(:id)

        @users.each do |user|
          submitted_role_ids = Array(submitted[user.id.to_s]).map(&:to_i) & allowed_role_ids
          current_role_ids   = current_tenant.assignments.where(user: user).pluck(:role_id) & allowed_role_ids

          (submitted_role_ids - current_role_ids).each do |role_id|
            current_tenant.assignments.create!(user: user, role_id: role_id)
          end

          (current_role_ids - submitted_role_ids).each do |role_id|
            current_tenant.assignments.where(user: user, role_id: role_id).destroy_all
          end
        end
      end

      redirect_to admin_assignments_path, notice: "ロール付与を更新しました。"
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "ロール付与の保存に失敗しました。#{e.record.errors.full_messages.to_sentence}"
      render :index, status: :unprocessable_entity
    end

    private

    def load_users_and_roles
      @users = current_tenant.users.includes(:roles).order(:name)
      @roles = current_tenant.roles.order(:name)
      @assignments = current_tenant.assignments.pluck(:user_id, :role_id).to_set
    end

    def assignment_params
      params.fetch(:assignments, {}).to_unsafe_h
    end
  end
end
