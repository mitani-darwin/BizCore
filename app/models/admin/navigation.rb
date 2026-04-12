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
          id: :ordering_master,
          label: "受発注マスタ",
          items: [
            Item.new(
              id: :customers,
              label: "得意先",
              path: :admin_customers_path,
              required_keys: %w[admin.customers.read],
              children: []
            ),
            Item.new(
              id: :products,
              label: "商品",
              path: :admin_products_path,
              required_keys: %w[admin.products.read],
              children: []
            ),
            Item.new(
              id: :warehouses,
              label: "倉庫",
              path: :admin_warehouses_path,
              required_keys: %w[admin.warehouses.read],
              children: []
            )
          ]
        ),
        Section.new(
          id: :procurement_master,
          label: "仕入マスタ",
          items: [
            Item.new(
              id: :suppliers,
              label: "仕入先",
              path: :admin_suppliers_path,
              required_keys: %w[admin.suppliers.read],
              children: []
            )
          ]
        ),
        Section.new(
          id: :inventory,
          label: "在庫管理",
          items: [
            Item.new(
              id: :stock_items,
              label: "在庫一覧",
              path: :admin_stock_items_path,
              required_keys: %w[admin.stock_items.read],
              children: []
            ),
            Item.new(
              id: :stock_movements,
              label: "在庫移動履歴",
              path: :admin_stock_movements_path,
              required_keys: %w[admin.stock_movements.read],
              children: []
            ),
            Item.new(
              id: :stock_counts,
              label: "棚卸",
              path: :admin_stock_counts_path,
              required_keys: %w[admin.stock_counts.read],
              children: []
            )
          ]
        ),
        Section.new(
          id: :ordering_flow,
          label: "受発注業務",
          items: [
            Item.new(
              id: :quotations,
              label: "見積",
              path: :admin_quotations_path,
              required_keys: %w[admin.quotations.read],
              children: []
            ),
            Item.new(
              id: :orders,
              label: "注文",
              path: :admin_orders_path,
              required_keys: %w[admin.orders.read],
              children: []
            ),
            Item.new(
              id: :deliveries,
              label: "納品",
              path: :admin_deliveries_path,
              required_keys: %w[admin.deliveries.read],
              children: []
            ),
            Item.new(
              id: :billing_batches,
              label: "請求締め",
              path: :admin_billing_batches_path,
              required_keys: %w[admin.billing_batches.read],
              children: []
            ),
            Item.new(
              id: :invoices,
              label: "請求",
              path: :admin_invoices_path,
              required_keys: %w[admin.invoices.read],
              children: []
            ),
            Item.new(
              id: :payments,
              label: "入金",
              path: :admin_payments_path,
              required_keys: %w[admin.payments.read],
              children: []
            ),
            Item.new(
              id: :receivables,
              label: "売掛残高",
              path: :admin_receivables_path,
              required_keys: %w[admin.receivables.read],
              children: []
            ),
            Item.new(
              id: :collection_schedules,
              label: "回収予定表",
              path: :admin_collection_schedules_path,
              required_keys: %w[admin.collection_schedules.read],
              children: []
            )
          ]
        ),
        Section.new(
          id: :procurement_flow,
          label: "発注業務",
          items: [
            Item.new(
              id: :purchase_orders,
              label: "発注",
              path: :admin_purchase_orders_path,
              required_keys: %w[admin.purchase_orders.read],
              children: []
            ),
            Item.new(
              id: :purchase_receipts,
              label: "入荷",
              path: :admin_purchase_receipts_path,
              required_keys: %w[admin.purchase_receipts.read],
              children: []
            ),
            Item.new(
              id: :purchase_adjustments,
              label: "返品/値引き",
              path: :admin_purchase_adjustments_path,
              required_keys: %w[admin.purchase_adjustments.read],
              children: []
            ),
            Item.new(
              id: :purchase_bill_batches,
              label: "仕入締め",
              path: :admin_purchase_bill_batches_path,
              required_keys: %w[admin.purchase_bill_batches.read],
              children: []
            ),
            Item.new(
              id: :purchase_bills,
              label: "仕入請求",
              path: :admin_purchase_bills_path,
              required_keys: %w[admin.purchase_bills.read],
              children: []
            ),
            Item.new(
              id: :supplier_payments,
              label: "支払",
              path: :admin_supplier_payments_path,
              required_keys: %w[admin.supplier_payments.read],
              children: []
            ),
            Item.new(
              id: :payables,
              label: "買掛残高",
              path: :admin_payables_path,
              required_keys: %w[admin.payables.read],
              children: []
            ),
            Item.new(
              id: :payment_schedules,
              label: "支払予定表",
              path: :admin_payment_schedules_path,
              required_keys: %w[admin.payment_schedules.read],
              children: []
            )
          ]
        ),
        Section.new(
          id: :access,
          label: "権限管理",
          items: [
            Item.new(
              id: :permissions,
              label: "権限定義",
              path: :admin_permissions_path,
              required_keys: %w[admin.permissions.read],
              children: []
            ),
            Item.new(
              id: :authorizations,
              label: "権限割当",
              path: :admin_authorization_path,
              required_keys: %w[admin.authorizations.read],
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
