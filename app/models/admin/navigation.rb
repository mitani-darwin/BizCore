module Admin
  # 管理画面サイドバーのナビゲーション構造を定義するクラス。
  # visible_sections はユーザーの権限に応じて表示項目をフィルタリングして返す。
  # サイドバー項目を追加・変更する場合は sections メソッド内の Section/Item を編集する。
  class Navigation
    Item = Struct.new(:id, :label, :path, :required_keys, :children, keyword_init: true)
    Section = Struct.new(:id, :label, :items, keyword_init: true)

    def self.sections
      [
        # ── 基本管理 ────────────────────────────────────────────
        Section.new(
          id: :core,
          label: "基本管理",
          items: [
            Item.new(id: :dashboard,          label: "ダッシュボード",   path: :admin_root_path,               required_keys: %w[admin.dashboard.read],          children: []),
            Item.new(id: :tenants,            label: "テナント",         path: :admin_tenants_path,            required_keys: %w[admin.tenants.read],            children: []),
            Item.new(id: :users,              label: "ユーザー",         path: :admin_users_path,              required_keys: %w[admin.users.read],              children: []),
            Item.new(id: :roles,              label: "ロール",           path: :admin_roles_path,              required_keys: %w[admin.roles.read],              children: []),
            Item.new(id: :document_templates, label: "帳票テンプレート", path: :admin_document_templates_path, required_keys: %w[admin.document_templates.read], children: [])
          ]
        ),
        # ── 人事・勤怠 ──────────────────────────────────────────
        Section.new(
          id: :workforce,
          label: "人事・勤怠",
          items: [
            Item.new(id: :employees,       label: "従業員",     path: :admin_employees_path,       required_keys: %w[admin.employees.read],       children: []),
            Item.new(id: :work_shifts,     label: "シフト",     path: :admin_work_shifts_path,     required_keys: %w[admin.work_shifts.read],     children: []),
            Item.new(id: :attendance_records, label: "勤怠",   path: :admin_attendance_records_path, required_keys: %w[admin.attendance_records.read], children: []),
            Item.new(id: :leave_requests,  label: "有給",       path: :admin_leave_requests_path,  required_keys: %w[admin.leave_requests.read],  children: []),
            Item.new(id: :leave_balances,  label: "有給残一覧", path: :admin_leave_balances_path,  required_keys: %w[admin.leave_balances.read],  children: []),
            Item.new(id: :payroll_runs,    label: "給与計算",   path: :admin_payroll_runs_path,    required_keys: %w[admin.payroll_runs.read],    children: []),
            Item.new(id: :expense_reports, label: "経費精算",   path: :admin_expense_reports_path, required_keys: %w[admin.expense_reports.read], children: [])
          ]
        ),
        # ── 営業・CRM ───────────────────────────────────────────
        Section.new(
          id: :sales,
          label: "営業・CRM",
          items: [
            Item.new(id: :customer_inquiries,    label: "問い合わせ", path: :admin_customer_inquiries_path,    required_keys: %w[admin.customer_inquiries.read],    children: []),
            Item.new(id: :customer_opportunities, label: "商談",     path: :admin_customer_opportunities_path, required_keys: %w[admin.customer_opportunities.read], children: []),
            Item.new(id: :customer_sales,        label: "売上",      path: :admin_customer_sales_path,        required_keys: %w[admin.customer_sales.read],        children: []),
            Item.new(id: :customers,             label: "得意先",    path: :admin_customers_path,             required_keys: %w[admin.customers.read],             children: []),
            Item.new(id: :contracts,             label: "契約",      path: :admin_contracts_path,             required_keys: %w[admin.contracts.read],             children: [])
          ]
        ),
        # ── 受注・請求 ──────────────────────────────────────────
        Section.new(
          id: :ordering,
          label: "受注・請求",
          items: [
            Item.new(id: :quotations,          label: "見積",       path: :admin_quotations_path,          required_keys: %w[admin.quotations.read],          children: []),
            Item.new(id: :orders,              label: "注文",       path: :admin_orders_path,              required_keys: %w[admin.orders.read],              children: []),
            Item.new(id: :deliveries,          label: "納品",       path: :admin_deliveries_path,          required_keys: %w[admin.deliveries.read],          children: []),
            Item.new(id: :billing_batches,     label: "請求締め",   path: :admin_billing_batches_path,     required_keys: %w[admin.billing_batches.read],     children: []),
            Item.new(id: :invoices,            label: "請求",       path: :admin_invoices_path,            required_keys: %w[admin.invoices.read],            children: []),
            Item.new(id: :payments,            label: "入金",       path: :admin_payments_path,            required_keys: %w[admin.payments.read],            children: []),
            Item.new(id: :receivables,         label: "売掛残高",   path: :admin_receivables_path,         required_keys: %w[admin.receivables.read],         children: []),
            Item.new(id: :collection_schedules, label: "回収予定表", path: :admin_collection_schedules_path, required_keys: %w[admin.collection_schedules.read], children: [])
          ]
        ),
        # ── 在庫管理 ────────────────────────────────────────────
        Section.new(
          id: :inventory,
          label: "在庫管理",
          items: [
            Item.new(id: :products,        label: "商品",       path: :admin_products_path,        required_keys: %w[admin.products.read],        children: []),
            Item.new(id: :warehouses,      label: "倉庫",       path: :admin_warehouses_path,      required_keys: %w[admin.warehouses.read],      children: []),
            Item.new(id: :stock_items,     label: "在庫一覧",   path: :admin_stock_items_path,     required_keys: %w[admin.stock_items.read],     children: []),
            Item.new(id: :stock_movements, label: "在庫移動履歴", path: :admin_stock_movements_path, required_keys: %w[admin.stock_movements.read], children: []),
            Item.new(id: :stock_counts,    label: "棚卸",       path: :admin_stock_counts_path,    required_keys: %w[admin.stock_counts.read],    children: [])
          ]
        ),
        # ── 仕入管理 ────────────────────────────────────────────
        Section.new(
          id: :procurement,
          label: "仕入管理",
          items: [
            Item.new(id: :suppliers,           label: "仕入先",    path: :admin_suppliers_path,           required_keys: %w[admin.suppliers.read],           children: []),
            Item.new(id: :purchase_orders,     label: "発注",      path: :admin_purchase_orders_path,     required_keys: %w[admin.purchase_orders.read],     children: []),
            Item.new(id: :purchase_receipts,   label: "入荷",      path: :admin_purchase_receipts_path,   required_keys: %w[admin.purchase_receipts.read],   children: []),
            Item.new(id: :purchase_adjustments, label: "返品/値引き", path: :admin_purchase_adjustments_path, required_keys: %w[admin.purchase_adjustments.read], children: []),
            Item.new(id: :purchase_bill_batches, label: "仕入締め", path: :admin_purchase_bill_batches_path, required_keys: %w[admin.purchase_bill_batches.read], children: []),
            Item.new(id: :purchase_bills,      label: "仕入請求",  path: :admin_purchase_bills_path,      required_keys: %w[admin.purchase_bills.read],      children: []),
            Item.new(id: :supplier_payments,   label: "支払",      path: :admin_supplier_payments_path,   required_keys: %w[admin.supplier_payments.read],   children: []),
            Item.new(id: :payables,            label: "買掛残高",  path: :admin_payables_path,            required_keys: %w[admin.payables.read],            children: []),
            Item.new(id: :payment_schedules,   label: "支払予定表", path: :admin_payment_schedules_path,  required_keys: %w[admin.payment_schedules.read],   children: [])
          ]
        ),
        # ── 現場管理 ────────────────────────────────────────────
        Section.new(
          id: :site_management,
          label: "現場管理",
          items: [
            Item.new(id: :sites,        label: "現場", path: :admin_sites_path,        required_keys: %w[admin.sites.read],        children: []),
            Item.new(id: :daily_reports, label: "日報", path: :admin_daily_reports_path, required_keys: %w[admin.daily_reports.read], children: [])
          ]
        ),
        # ── 会計連携 ────────────────────────────────────────────
        Section.new(
          id: :accounting,
          label: "会計連携",
          items: [
            Item.new(id: :accounting_exports, label: "会計ソフト連携", path: :admin_accounting_exports_path, required_keys: %w[admin.accounting_exports.read], children: [])
          ]
        ),
        # ── 権限・システム ──────────────────────────────────────
        Section.new(
          id: :system,
          label: "権限・システム",
          items: [
            Item.new(id: :permissions,    label: "権限定義",  path: :admin_permissions_path,    required_keys: %w[admin.permissions.read],    children: []),
            Item.new(id: :authorizations, label: "権限割当",  path: :admin_authorization_path,  required_keys: %w[admin.authorizations.read], children: []),
            Item.new(id: :assignments,    label: "ロール付与", path: :admin_assignments_path,    required_keys: %w[admin.assignments.read],    children: []),
            Item.new(id: :audit_logs,     label: "監査ログ",  path: :admin_audit_logs_path,     required_keys: %w[admin.audit_logs.read],     children: [])
          ]
        )
      ]
    end

    def self.visible_sections(context)
      tenant = context.respond_to?(:current_tenant) ? context.current_tenant : nil
      sections
        .select { |section| FeatureFlags.section_enabled?(section.id, tenant: tenant) }
        .map { |section| filter_section(section, context) }
        .compact
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
