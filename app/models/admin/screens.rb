module Admin
  class Screens
    Action = Struct.new(
      :name,
      :label,
      :permission_key,
      :breadcrumb_label,
      :page_title,
      keyword_init: true
    )
    Screen = Struct.new(:id, :label, :resource, :index_path, :actions, keyword_init: true)

    DEFAULT_ACTIONS = {
      index: { permission_action: :read, label: "一覧", page_title: "%{resource}一覧" },
      show: { permission_action: :read, label: "詳細", page_title: "%{resource}詳細" },
      new: { permission_action: :create, label: "新規作成", page_title: "%{resource}新規作成" },
      create: { permission_action: :create, label: "新規作成", page_title: "%{resource}新規作成" },
      edit: { permission_action: :update, label: "編集", page_title: "%{resource}編集" },
      update: { permission_action: :update, label: "編集", page_title: "%{resource}編集" },
      destroy: { permission_action: :delete, label: "削除", page_title: "%{resource}削除" }
    }.freeze

    SCREEN_DEFS = {
      dashboard: {
        label: "ダッシュボード",
        index_path: :admin_root_path,
        actions: %i[index],
        action_overrides: {
          index: { label: "ダッシュボード", breadcrumb_label: "ダッシュボード", page_title: "ダッシュボード" }
        }
      },
      tenants: {
        index_path: :admin_tenants_path,
        actions: %i[index show new create edit update]
      },
      users: {
        index_path: :admin_users_path,
        actions: %i[index show new create edit update]
      },
      roles: {
        index_path: :admin_roles_path,
        actions: %i[index show new create edit update]
      },
      permissions: {
        index_path: :admin_permissions_path,
        actions: %i[index create update destroy]
      },
      authorizations: {
        label: "権限管理",
        index_path: :admin_authorization_path,
        actions: %i[show update],
        action_overrides: {
          show: { label: "一覧", page_title: "権限管理", breadcrumb_label: "権限管理" },
          update: { label: "更新", page_title: "権限管理", breadcrumb_label: "権限管理" }
        }
      },
      audit_logs: {
        index_path: :admin_audit_logs_path,
        actions: %i[index show]
      }
    }.freeze

    def self.screen_for(controller_name)
      key = controller_name.to_s.to_sym
      definition = SCREEN_DEFS[key]
      return nil unless definition

      resource = definition.fetch(:resource, key)
      label = definition[:label] || Permissions::Catalog.resource_label(resource)
      Screen.new(
        id: key,
        label: label,
        resource: resource,
        index_path: definition[:index_path],
        actions: build_actions(resource, label, definition)
      )
    end

    def self.action_for(controller_name, action_name)
      screen = screen_for(controller_name)
      return nil unless screen

      screen.actions[action_name.to_s.to_sym]
    end

    def self.page_title_for(controller_name, action_name, record: nil)
      screen = screen_for(controller_name)
      return nil unless screen

      action = action_for(controller_name, action_name)
      return screen.label unless action&.page_title

      format(action.page_title, resource: screen.label, record: record_label(record))
    end

    def self.breadcrumbs_for(context, controller_name, action_name, record: nil)
      screen = screen_for(controller_name)
      return [] unless screen

      crumbs = []
      if context.respond_to?(:admin_root_path)
        crumbs << { label: "ダッシュボード", path: context.admin_root_path }
      end

      return crumbs if screen.id == :dashboard

      index_path = resolve_path(screen.index_path, context, record)
      crumbs << { label: screen.label, path: index_path } if screen.label

      action = action_for(controller_name, action_name)
      return crumbs if action.nil? || action.name == :index

      if record && action.name == :show
        crumbs << { label: record_label(record), path: nil }
        return crumbs
      end

      if record && %i[edit update].include?(action.name)
        crumbs << { label: record_label(record), path: nil }
      end

      return crumbs if action.breadcrumb_label == screen.label

      crumbs << { label: action.breadcrumb_label || action.label, path: nil }
      crumbs
    end

    def self.resolve_path(path, context, record)
      return nil if path.nil?
      return path.call(context, record) if path.respond_to?(:call)
      return context.public_send(path) if path.is_a?(Symbol)

      path
    end

    def self.build_actions(resource, label, definition)
      overrides = definition[:action_overrides] || {}
      Array(definition[:actions]).each_with_object({}) do |name, hash|
        default = DEFAULT_ACTIONS.fetch(name, {})
        custom = overrides[name] || {}
        permission_action = custom.fetch(:permission_action, default[:permission_action])
        permission_key = permission_action ? Permissions::Catalog.admin_key(resource, permission_action) : nil
        action_label = custom.fetch(:label, default[:label])
        page_title = custom.fetch(:page_title, default[:page_title])
        breadcrumb_label = custom.fetch(:breadcrumb_label, action_label)
        hash[name] = Action.new(
          name: name,
          label: action_label,
          permission_key: permission_key,
          breadcrumb_label: breadcrumb_label,
          page_title: page_title
        )
      end
    end

    def self.record_label(record)
      return nil unless record
      return record.name if record.respond_to?(:name) && record.name.present?
      return record.title if record.respond_to?(:title) && record.title.present?

      if record.respond_to?(:id) && record.class.respond_to?(:model_name)
        return "#{record.class.model_name.human}##{record.id}"
      end

      record.to_s
    end

    private_class_method :build_actions, :record_label, :resolve_path
  end
end
