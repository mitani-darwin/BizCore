module Admin
  # 管理画面の画面メタデータ（タイトル・パンくず・権限キー）を集中管理するクラス。
  # Admin::BaseController からリクエストごとに呼び出され、画面タイトルとパンくずを組み立てる。
  # 新規画面を追加する際は SCREEN_DEFS にエントリを追加する。
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
      employees: {
        index_path: :admin_employees_path,
        actions: %i[index show new create edit update destroy],
        action_overrides: {
          destroy: { permission_action: :delete, label: "削除", breadcrumb_label: "削除" }
        }
      },
      work_shifts: {
        index_path: :admin_work_shifts_path,
        actions: %i[index show new create edit update destroy grid],
        action_overrides: {
          grid: { permission_action: :read, label: "グリッド入力", breadcrumb_label: "グリッド入力", page_title: "シフトグリッド" },
          destroy: { permission_action: :delete, label: "削除", breadcrumb_label: "削除" }
        }
      },
      attendance_records: {
        index_path: :admin_attendance_records_path,
        actions: %i[index show new create edit update clock_in clock_out close_month],
        action_overrides: {
          clock_in:    { permission_action: :create, label: "出勤打刻",  breadcrumb_label: "出勤打刻",  page_title: "%{resource}一覧" },
          clock_out:   { permission_action: :update, label: "退勤打刻",  breadcrumb_label: "退勤打刻",  page_title: "%{resource}詳細" },
          close_month: { permission_action: :update, label: "月次締め",  breadcrumb_label: "月次締め",  page_title: "%{resource}一覧" }
        }
      },
      leave_requests: {
        index_path: :admin_leave_requests_path,
        actions: %i[index show new create edit update approve reject],
        action_overrides: {
          approve: { permission_action: :update, label: "承認", breadcrumb_label: "承認", page_title: "%{resource}詳細" },
          reject: { permission_action: :update, label: "却下", breadcrumb_label: "却下", page_title: "%{resource}詳細" }
        }
      },
      leave_balances: {
        index_path: :admin_leave_balances_path,
        actions: %i[index]
      },
      payroll_runs: {
        index_path: :admin_payroll_runs_path,
        actions: %i[index show generate confirm download_excel download_pdf],
        action_overrides: {
          generate:       { permission_action: :create, label: "給与反映",   breadcrumb_label: "給与反映",   page_title: "%{resource}一覧" },
          confirm:        { permission_action: :update, label: "確定",       breadcrumb_label: "確定",       page_title: "%{resource}詳細" },
          download_excel: { permission_action: :read,   label: "Excel出力",  breadcrumb_label: "Excel出力",  page_title: "%{resource}詳細" },
          download_pdf:   { permission_action: :read,   label: "PDF出力",    breadcrumb_label: "PDF出力",    page_title: "%{resource}詳細" }
        }
      },
      suppliers: {
        index_path: :admin_suppliers_path,
        actions: %i[index show new create edit update]
      },
      roles: {
        index_path: :admin_roles_path,
        actions: %i[index show new create edit update]
      },
      customer_inquiries: {
        index_path: :admin_customer_inquiries_path,
        actions: %i[index show new create edit update]
      },
      customer_opportunities: {
        index_path: :admin_customer_opportunities_path,
        actions: %i[index show new create edit update]
      },
      customer_sales: {
        index_path: :admin_customer_sales_path,
        actions: %i[index]
      },
      customers: {
        index_path: :admin_customers_path,
        actions: %i[index show new create edit update destroy],
        action_overrides: {
          destroy: { permission_action: :delete, label: "削除", breadcrumb_label: "削除" }
        }
      },
      receivables: {
        index_path: :admin_receivables_path,
        actions: %i[index]
      },
      collection_schedules: {
        index_path: :admin_collection_schedules_path,
        actions: %i[index]
      },
      products: {
        index_path: :admin_products_path,
        actions: %i[index show new create edit update]
      },
      warehouses: {
        index_path: :admin_warehouses_path,
        actions: %i[index show new create edit update]
      },
      stock_items: {
        index_path: :admin_stock_items_path,
        actions: %i[index show new create edit update]
      },
      stock_movements: {
        index_path: :admin_stock_movements_path,
        actions: %i[index show new create]
      },
      stock_counts: {
        index_path: :admin_stock_counts_path,
        actions: %i[index new create]
      },
      purchase_orders: {
        index_path: :admin_purchase_orders_path,
        actions: %i[index show new create edit update download_excel send_purchase_order receive_items],
        action_overrides: {
          download_excel: { permission_action: :read, label: "Excel出力", breadcrumb_label: "Excel出力", page_title: "%{resource}詳細" },
          send_purchase_order: { permission_action: :update, label: "発注書送信", breadcrumb_label: "発注書送信", page_title: "%{resource}詳細" },
          receive_items: { permission_action: :update, label: "入荷登録", breadcrumb_label: "入荷登録", page_title: "%{resource}詳細" }
        }
      },
      purchase_receipts: {
        index_path: :admin_purchase_receipts_path,
        actions: %i[index show download_excel],
        action_overrides: {
          download_excel: { permission_action: :read, label: "Excel出力", breadcrumb_label: "Excel出力", page_title: "%{resource}詳細" }
        }
      },
      purchase_adjustments: {
        index_path: :admin_purchase_adjustments_path,
        actions: %i[index show create]
      },
      purchase_bill_batches: {
        index_path: :admin_purchase_bill_batches_path,
        actions: %i[index show cancel],
        action_overrides: {
          cancel: { permission_action: :update, label: "締め解除", breadcrumb_label: "締め解除", page_title: "%{resource}詳細" }
        }
      },
      purchase_bills: {
        index_path: :admin_purchase_bills_path,
        actions: %i[index show download_excel issue_monthly cancel reissue],
        action_overrides: {
          download_excel: { permission_action: :read, label: "Excel出力", breadcrumb_label: "Excel出力", page_title: "%{resource}詳細" },
          issue_monthly: { permission_action: :create, label: "月次仕入請求", breadcrumb_label: "月次仕入請求", page_title: "%{resource}一覧" },
          cancel: { permission_action: :update, label: "請求取消", breadcrumb_label: "請求取消", page_title: "%{resource}詳細" },
          reissue: { permission_action: :create, label: "再発行", breadcrumb_label: "再発行", page_title: "%{resource}詳細" }
        }
      },
      supplier_payments: {
        index_path: :admin_supplier_payments_path,
        actions: %i[index show new create edit update reconcile],
        action_overrides: {
          reconcile: { permission_action: :update, label: "消し込み", breadcrumb_label: "消し込み", page_title: "%{resource}詳細" }
        }
      },
      payables: {
        index_path: :admin_payables_path,
        actions: %i[index]
      },
      payment_schedules: {
        index_path: :admin_payment_schedules_path,
        actions: %i[index]
      },
      quotations: {
        index_path: :admin_quotations_path,
        actions: %i[index show new create edit update download_excel send_quotation accept_quotation create_order],
        action_overrides: {
          download_excel: { permission_action: :read, label: "Excel出力", breadcrumb_label: "Excel出力", page_title: "%{resource}詳細" },
          send_quotation: { permission_action: :update, label: "見積書送信", breadcrumb_label: "見積書送信", page_title: "%{resource}詳細" },
          accept_quotation: { permission_action: :update, label: "採用", breadcrumb_label: "採用", page_title: "%{resource}詳細" },
          create_order: { permission_action: :update, label: "注文へ変換", breadcrumb_label: "注文へ変換", page_title: "%{resource}詳細" }
        }
      },
      orders: {
        index_path: :admin_orders_path,
        actions: %i[index show new create edit update download_excel send_order accept_order reserve_stock issue_delivery],
        action_overrides: {
          download_excel: { permission_action: :read, label: "Excel出力", breadcrumb_label: "Excel出力", page_title: "%{resource}詳細" },
          send_order: { permission_action: :update, label: "注文書送信", breadcrumb_label: "注文書送信", page_title: "%{resource}詳細" },
          accept_order: { permission_action: :update, label: "受注確定", breadcrumb_label: "受注確定", page_title: "%{resource}詳細" },
          reserve_stock: { permission_action: :update, label: "在庫確保", breadcrumb_label: "在庫確保", page_title: "%{resource}詳細" },
          issue_delivery: { permission_action: :update, label: "納品書発行", breadcrumb_label: "納品書発行", page_title: "%{resource}詳細" }
        }
      },
      deliveries: {
        index_path: :admin_deliveries_path,
        actions: %i[index show download_excel],
        action_overrides: {
          download_excel: { permission_action: :read, label: "Excel出力", breadcrumb_label: "Excel出力", page_title: "%{resource}詳細" }
        }
      },
      billing_batches: {
        index_path: :admin_billing_batches_path,
        actions: %i[index show cancel],
        action_overrides: {
          cancel: { permission_action: :update, label: "締め解除", breadcrumb_label: "締め解除", page_title: "%{resource}詳細" }
        }
      },
      invoices: {
        index_path: :admin_invoices_path,
        actions: %i[index show download_excel issue_monthly cancel reissue export_csv],
        action_overrides: {
          download_excel: { permission_action: :read, label: "Excel出力", breadcrumb_label: "Excel出力", page_title: "%{resource}詳細" },
          issue_monthly: { permission_action: :create, label: "月末請求", breadcrumb_label: "月末請求", page_title: "%{resource}一覧" },
          cancel: { permission_action: :update, label: "請求取消", breadcrumb_label: "請求取消", page_title: "%{resource}詳細" },
          reissue: { permission_action: :create, label: "再発行", breadcrumb_label: "再発行", page_title: "%{resource}詳細" },
          export_csv: { permission_action: :read, label: "CSV出力", breadcrumb_label: "CSV出力", page_title: "%{resource}一覧" }
        }
      },
      payments: {
        index_path: :admin_payments_path,
        actions: %i[index show new create edit update reconcile],
        action_overrides: {
          reconcile: { permission_action: :update, label: "消し込み", breadcrumb_label: "消し込み", page_title: "%{resource}詳細" }
        }
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
      assignments: {
        label: "ロール付与",
        index_path: :admin_assignments_path,
        actions: %i[index create],
        action_overrides: {
          index:  { label: "一覧",   page_title: "ロール付与",  breadcrumb_label: "ロール付与" },
          create: { permission_action: :create, label: "更新", page_title: "ロール付与", breadcrumb_label: "ロール付与" }
        }
      },
      document_templates: {
        index_path: :admin_document_templates_path,
        actions: %i[index edit update],
        action_overrides: {
          edit: { permission_action: :update, label: "編集", breadcrumb_label: "編集", page_title: "%{resource}編集" },
          update: { permission_action: :update, label: "編集", breadcrumb_label: "編集", page_title: "%{resource}編集" }
        }
      },
      audit_logs: {
        index_path: :admin_audit_logs_path,
        actions: %i[index show]
      },
      sites: {
        index_path: :admin_sites_path,
        actions: %i[index show new create edit update update_progress],
        action_overrides: {
          update_progress: {
            permission_action: :update,
            label: "進捗更新",
            breadcrumb_label: "進捗更新",
            page_title: "%{resource}詳細"
          }
        }
      },
      daily_reports: {
        index_path: :admin_daily_reports_path,
        actions: %i[index show new create edit update destroy]
      },
      contracts: {
        index_path: :admin_contracts_path,
        actions: %i[index show new create edit update]
      },
      accounting_exports: {
        label: "会計ソフト連携",
        index_path: :admin_accounting_exports_path,
        actions: %i[index export_csv],
        action_overrides: {
          export_csv: { permission_action: :read, label: "CSV出力", breadcrumb_label: "CSV出力", page_title: "会計ソフト連携" }
        }
      },
      expense_reports: {
        index_path: :admin_expense_reports_path,
        actions: %i[index show new create edit update approve reject],
        action_overrides: {
          approve: { permission_action: :update, label: "承認", breadcrumb_label: "承認", page_title: "%{resource}詳細" },
          reject:  { permission_action: :update, label: "却下", breadcrumb_label: "却下", page_title: "%{resource}詳細" }
        }
      },
      profile: {
        label: "プロフィール",
        index_path: :edit_password_admin_profile_path,
        actions: %i[edit_password update_password],
        action_overrides: {
          edit_password:   { permission_action: nil, label: "パスワード変更", breadcrumb_label: "パスワード変更", page_title: "パスワード変更" },
          update_password: { permission_action: nil, label: "パスワード変更", breadcrumb_label: "パスワード変更", page_title: "パスワード変更" }
        }
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
      return record.order_number if record.respond_to?(:order_number) && record.order_number.present?
      return record.purchase_order_number if record.respond_to?(:purchase_order_number) && record.purchase_order_number.present?
      return record.purchase_receipt_number if record.respond_to?(:purchase_receipt_number) && record.purchase_receipt_number.present?
      return record.adjustment_number if record.respond_to?(:adjustment_number) && record.adjustment_number.present?
      return record.batch_number if record.respond_to?(:batch_number) && record.batch_number.present?
      return record.bill_number if record.respond_to?(:bill_number) && record.bill_number.present?
      return record.quotation_number if record.respond_to?(:quotation_number) && record.quotation_number.present?
      return record.delivery_number if record.respond_to?(:delivery_number) && record.delivery_number.present?
      return record.invoice_number if record.respond_to?(:invoice_number) && record.invoice_number.present?
      return record.payment_number if record.respond_to?(:payment_number) && record.payment_number.present?
      return record.code if record.respond_to?(:code) && record.code.present?

      if record.respond_to?(:id) && record.class.respond_to?(:model_name)
        return "#{record.class.model_name.human}##{record.id}"
      end

      record.to_s
    end

    private_class_method :build_actions, :record_label, :resolve_path
  end
end
