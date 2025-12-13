module Admin
  class RolesController < ApplicationController
    before_action :set_tenant
    before_action :set_search_params, only: [:index, :create]

    def index
      authorize([:admin, Role], :manage?)

      @roles = policy_scope([:admin, Role]).where(tenant: @tenant).order(:name)
      @tenant_search_name = @tenant.name
      @tenant_search_code = @tenant.code
      @tenant_search_subdomain = @tenant.subdomain
      @tenant_options = [@tenant].compact
      @tenant_search_results = [@tenant].compact
    end

    def create
      authorize([:admin, Role], :manage?)

      new_roles = role_params
      created = []

      ActiveRecord::Base.transaction do
        new_roles.each do |attrs|
          next if attrs.values.all?(&:blank?)

          role = @tenant.roles.build(attrs)
          if role.save
            created << role
          else
            @errors = role.errors.full_messages
            raise ActiveRecord::Rollback
          end
        end
      end

      if created.any? && @errors.blank?
        redirect_to admin_tenant_roles_path(@tenant), notice: "ロールを保存しました。"
      else
        @roles = @tenant.roles.order(:name)
        @tenant_options = Tenant.order(:id).limit(100)
        @tenant_search_results = search_tenants(@tenant_search_name, @tenant_search_code, @tenant_search_subdomain)
        flash.now[:alert] = @errors&.join(", ") || "保存するロールがありません。"
        render :index, status: :unprocessable_entity
      end
    end

    private

    def set_tenant
      @tenant = current_tenant
      raise Pundit::NotAuthorizedError unless @tenant.present? && params[:tenant_id].to_s == @tenant.id.to_s
    end

    def set_search_params
      @tenant_search_name = params[:tenant_name].to_s.strip
      @tenant_search_code = params[:tenant_code].to_s.strip
      @tenant_search_subdomain = params[:tenant_subdomain].to_s.strip
    end

    def role_params
      params.fetch(:roles, []).map do |role|
        role.permit(:name, :key, :description)
      end
    end
  end
end
