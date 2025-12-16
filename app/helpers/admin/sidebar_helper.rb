module Admin
  module SidebarHelper
    SidebarItem = Struct.new(:label, :path, :permission_keys, :controllers, keyword_init: true)
    SidebarSection = Struct.new(:label, :items, keyword_init: true)

    def sidebar_sections
      sections = [
        SidebarSection.new(
          label: "基本管理",
          items: [
            SidebarItem.new(
              label: "ダッシュボード",
              path: admin_root_path,
              permission_keys: %w[admin.dashboard.index],
              controllers: %w[dashboard]
            ),
            SidebarItem.new(
              label: "テナント",
              path: admin_tenants_path,
              permission_keys: %w[
                admin.tenants.index
                admin.tenants.show
                admin.tenants.create
                admin.tenants.update
                admin.tenants.destroy
              ],
              controllers: %w[tenants]
            ),
            SidebarItem.new(
              label: "ユーザー",
              path: admin_users_path,
              permission_keys: %w[
                admin.users.index
                admin.users.show
                admin.users.create
                admin.users.update
                admin.users.destroy
              ],
              controllers: %w[users]
            )
          ]
        ),
        SidebarSection.new(
          label: "権限管理",
          items: [
            SidebarItem.new(
              label: "ロール",
              path: admin_roles_path,
              permission_keys: %w[
                admin.roles.index
                admin.roles.show
                admin.roles.create
                admin.roles.update
                admin.roles.destroy
              ],
              controllers: %w[roles]
            ),
            SidebarItem.new(
              label: "権限定義",
              path: admin_permissions_path,
              permission_keys: %w[
                admin.permissions.index
                admin.permissions.create
                admin.permissions.update
                admin.permissions.destroy
              ],
              controllers: %w[permissions]
            ),
            SidebarItem.new(
              label: "権限割当",
              path: admin_authorization_path,
              permission_keys: %w[
                admin.authorizations.show
                admin.authorizations.update
              ],
              controllers: %w[authorizations]
            )
          ]
        )
      ]

      sections
        .map { |section| filter_section(section) }
        .compact
    end

    def visible?(keys)
      Array(keys).any? { |k| can?(k) }
    end

    def active_item?(item)
      item.controllers.any? { |c| controller_name == c } || current_page?(item.path)
    end

    private

    def filter_section(section)
      filtered_items = section.items.select { |item| visible?(item.permission_keys) }
      return nil if filtered_items.empty?

      SidebarSection.new(label: section.label, items: filtered_items)
    end
  end
end
