module Admin
  class Navigation
    Item = Struct.new(:id, :label, :path, :required_keys, :children, keyword_init: true)
    Section = Struct.new(:id, :label, :items, keyword_init: true)

    def self.sections
      [
        Section.new(
          id: :core,
          label: "基本管理",
          items: [
            Item.new(
              id: :dashboard,
              label: "ダッシュボード",
              path: :admin_root_path,
              required_keys: %w[admin.dashboard.read],
              children: []
            ),
            Item.new(
              id: :tenants,
              label: "テナント",
              path: :admin_tenants_path,
              required_keys: %w[admin.tenants.read],
              children: []
            ),
            Item.new(
              id: :users,
              label: "ユーザー",
              path: :admin_users_path,
              required_keys: %w[admin.users.read],
              children: []
            ),
            Item.new(
              id: :roles,
              label: "ロール",
              path: :admin_roles_path,
              required_keys: %w[admin.roles.read],
              children: []
            )
          ]
        ),
        Section.new(
          id: :audit,
          label: "監査",
          items: [
            Item.new(
              id: :audit_logs,
              label: "監査ログ",
              path: :admin_audit_logs_path,
              required_keys: %w[admin.audit_logs.read],
              children: []
            )
          ]
        )
      ]
    end

    def self.visible_sections(context)
      sections.map { |section| filter_section(section, context) }.compact
    end

    def self.resolve_path(item, context)
      return nil if item.path.nil?
      return item.path.call(context) if item.path.respond_to?(:call)
      return context.public_send(item.path) if item.path.is_a?(Symbol)

      item.path
    end

    def self.filter_section(section, context)
      items = section.items.map { |item| filter_item(item, context) }.compact
      return nil if items.empty?

      Section.new(id: section.id, label: section.label, items: items)
    end

    def self.filter_item(item, context)
      children = item.children.map { |child| filter_item(child, context) }.compact
      visible = visible_item?(item, context)
      return nil unless visible || children.any?

      Item.new(
        id: item.id,
        label: item.label,
        path: item.path,
        required_keys: item.required_keys,
        children: children
      )
    end

    def self.visible_item?(item, context)
      keys = Array(item.required_keys)
      return true if keys.empty?

      keys.any? { |key| context.can?(key) }
    end

    private_class_method :filter_section, :filter_item, :visible_item?
  end
end
