module Admin
  # ユーザーの CRUD を管理する。パスワードは Devise が扱うため strong parameters に含めない。
  class UsersController < BaseController
    before_action :set_user, only: [ :show, :edit, :update ]
    before_action :set_role_options, only: [ :new, :create, :edit, :update ]
    before_action :set_employee_options, only: [ :new, :create, :edit, :update ]

    def index
      @pagy, @users = pagy(current_tenant.users.includes(:roles, :employee).order(:id))
    end

    def show; end

    def new
      @user = current_tenant.users.build(
        time_zone: "Asia/Tokyo",
        locale: "ja"
      )
    end

    def create
      @user = current_tenant.users.build(user_params)
      assign_roles(@user)

      if @user.save
        redirect_to admin_users_path, notice: "ユーザを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @user.assign_attributes(user_params)
      assign_roles(@user)

      if @user.save
        redirect_to admin_user_path(@user), notice: "ユーザを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = current_tenant.users.find_by(id: params[:id])
      return if @user

      render_not_found and return false
    end

    def set_role_options
      @role_options = current_tenant.roles.order(:name)
    end

    def set_employee_options
      @employee_options = current_tenant.employees.ordered_for_admin.to_a
      return unless @user&.employee.present?

      @employee_options |= [ @user.employee ]
      @employee_options.sort_by! { |employee| [ employee.employee_code.to_s, employee.id ] }
    end

    def assign_roles(user)
      selected_ids = role_ids_param
      allowed_ids = @role_options.pluck(:id)
      user.role_ids = selected_ids & allowed_ids
    end

    def role_ids_param
      Array(params.dig(:user, :role_ids)).reject(&:blank?).map(&:to_i)
    end

    def user_params
      permitted = params.require(:user).permit(
        :name,
        :email,
        :employee_id,
        :line_id,
        :password,
        :password_confirmation,
        :is_owner,
        :locale,
        :time_zone
      )

      if permitted[:password].blank?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end

      permitted
    end
  end
end
