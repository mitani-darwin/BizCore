module Admin
  # ログイン中ユーザー自身のプロフィール操作（パスワード変更など）を担うコントローラ。
  # 権限チェックは不要（認証済みであれば誰でも自分のパスワードを変更できる）。
  class ProfileController < BaseController
    def edit_password; end

    def update_password
      if current_user.update_with_password(password_params)
        bypass_sign_in(current_user)
        redirect_to edit_password_admin_profile_path, notice: "パスワードを変更しました。"
      else
        render :edit_password, status: :unprocessable_entity
      end
    end

    private

    def require_permission!
      # 自分自身のパスワード変更は全認証済みユーザーに許可する
    end

    def password_params
      params.require(:user).permit(:current_password, :password, :password_confirmation)
    end
  end
end
