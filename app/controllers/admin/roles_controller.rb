module Admin
  class RolesController < ApplicationController
    before_action :set_tenant
    before_action :set_search_params, only: [:index, :create]

    def index
      @roles = @tenant.roles.order(:name)
      @tenant_search_name = params[:tenant_name].to_s.strip
      @tenant_search_code = params[:tenant_code].to_s.strip
      @tenant_search_subdomain = params[:tenant_subdomain].to_s.strip
      @tenant_options = Tenant.order(:id).limit(100)
      @tenant_search_results = search_tenants(@tenant_search_name, @tenant_search_code, @tenant_search_subdomain)
    end

    def create
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
      @tenant = Tenant.find(params[:tenant_id])
    end

    def set_search_params
      @tenant_search_name = params[:tenant_name].to_s.strip
      @tenant_search_code = params[:tenant_code].to_s.strip
      @tenant_search_subdomain = params[:tenant_subdomain].to_s.strip
    end

    def search_tenants(name, code, subdomain)
      return [] if name.blank? && code.blank? && subdomain.blank?

      scope = Tenant.all
      scope = scope.where(Tenant.arel_table[:name].matches("%#{name}%")) if name.present?
      scope = scope.where(Tenant.arel_table[:code].matches("%#{code}%")) if code.present?
      scope = scope.where(Tenant.arel_table[:subdomain].matches("%#{subdomain}%")) if subdomain.present?
      scope.order(:name).limit(10)
    end

    def role_params
      params.fetch(:roles, []).map do |role|
        role.permit(:name, :key, :description)
      end
    end
  end
end
