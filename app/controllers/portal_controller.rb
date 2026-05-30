# ログイン後のエントリポイント。管理画面へのアクセス権がある場合はリダイレクト、
# 従業員のみの場合はセルフポータル画面を表示する。いずれも権限がない場合はログイン画面に戻す。
class PortalController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_current_tenant!

  def index
    admin_path = first_admin_path
    if admin_path.present?
      redirect_to admin_path
      return
    end

    if current_employee.present?
      @admin_entry_path = first_admin_path
      render :index
      return
    end

    reset_session
    redirect_to new_user_session_path, alert: "利用可能な画面がありません。管理者にお問い合わせください。"
  end

  private

  def ensure_current_tenant!
    return if current_tenant.present?

    render_not_found
  end

  def first_admin_path
    Admin::Navigation.visible_sections(self).flat_map(&:items).map { |item| Admin::Navigation.resolve_path(item, self) }.compact.first
  end
end
