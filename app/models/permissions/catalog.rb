module Permissions
  class Catalog
    ADMIN_RESOURCES = {
      dashboard: %i[read],
      tenants: %i[read create update delete],
      users: %i[read create update delete],
      roles: %i[read create update delete],
      employees: %i[read create update delete],
      work_shifts: %i[read create update delete],
      attendance_records: %i[read create update delete],
      leave_requests: %i[read create update delete],
      payroll_runs: %i[read create update delete],
      customer_inquiries: %i[read create update delete],
      customer_opportunities: %i[read create update delete],
      customer_sales: %i[read],
      suppliers: %i[read create update delete],
      customers: %i[read create update delete],
      receivables: %i[read],
      payables: %i[read],
      collection_schedules: %i[read],
      payment_schedules: %i[read],
      products: %i[read create update delete],
      warehouses: %i[read create update delete],
      stock_items: %i[read create update delete],
      stock_movements: %i[read create],
      stock_counts: %i[read create],
      purchase_orders: %i[read create update delete download_excel download_pdf],
      purchase_receipts: %i[read create update delete download_excel download_pdf],
      purchase_adjustments: %i[read create update delete],
      purchase_bill_batches: %i[read create update delete],
      purchase_bills: %i[read create update delete download_excel download_pdf],
      supplier_payments: %i[read create update delete],
      quotations: %i[read create update delete download_excel download_pdf],
      orders: %i[read create update delete download_excel download_pdf],
      deliveries: %i[read create update delete download_excel download_pdf],
      billing_batches: %i[read create update delete],
      invoices: %i[read create update delete download_excel download_pdf],
      payments: %i[read create update delete],
      document_templates: %i[read update],
      permissions: %i[read create update delete],
      authorizations: %i[read update],
      assignments: %i[read create delete],
      audit_logs: %i[read],
      sites: %i[read create update delete],
      daily_reports: %i[read]
    }.freeze

    RESOURCE_LABELS = {
      dashboard: "ダッシュボード",
      tenants: "テナント",
      users: "ユーザー",
      roles: "ロール",
      employees: "従業員",
      work_shifts: "シフト",
      attendance_records: "勤怠",
      leave_requests: "有給",
      payroll_runs: "給与計算",
      customer_inquiries: "問い合わせ",
      customer_opportunities: "商談",
      customer_sales: "売上",
      suppliers: "仕入先",
      customers: "得意先",
      receivables: "売掛残高",
      payables: "買掛残高",
      collection_schedules: "回収予定表",
      payment_schedules: "支払予定表",
      products: "商品",
      warehouses: "倉庫",
      stock_items: "在庫",
      stock_movements: "在庫移動",
      stock_counts: "棚卸",
      purchase_orders: "発注",
      purchase_receipts: "入荷",
      purchase_adjustments: "返品/値引き",
      purchase_bill_batches: "仕入締め",
      purchase_bills: "仕入請求",
      supplier_payments: "支払",
      quotations: "見積",
      orders: "注文",
      deliveries: "納品",
      billing_batches: "請求締め",
      invoices: "請求",
      payments: "入金",
      document_templates: "帳票テンプレート",
      permissions: "権限定義",
      authorizations: "権限割当",
      assignments: "ロール付与",
      audit_logs: "監査ログ",
      sites: "現場",
      daily_reports: "日報"
    }.freeze

    ACTION_LABELS = {
      read: "閲覧",
      create: "作成",
      update: "更新",
      delete: "削除"
    }.freeze

    def self.admin_entries
      now = Time.current
      ADMIN_RESOURCES.flat_map do |resource, actions|
        actions.map do |action|
          key = admin_key(resource, action)
          {
            key: key,
            resource: resource.to_s,
            action: action.to_s,
            name: "#{resource_label(resource)}: #{action_label(action)}",
            description: "権限キー: #{key}",
            category: resource.to_s,
            created_at: now,
            updated_at: now
          }
        end
      end
    end

    def self.admin_keys
      admin_entries.map { |entry| entry[:key] }
    end

    def self.admin_key(resource, action)
      "admin.#{resource}.#{action}"
    end

    def self.seed_admin!
      Permission.upsert_all(
        admin_entries,
        unique_by: :key,
        record_timestamps: false
      )
      Permission.where(key: admin_keys).index_by(&:key)
    end

    def self.resource_label(resource)
      RESOURCE_LABELS.fetch(resource.to_sym, resource.to_s.humanize)
    end

    def self.action_label(action)
      ACTION_LABELS.fetch(action.to_sym, action.to_s.humanize)
    end
  end
end
