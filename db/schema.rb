# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_21_111157) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_assignments_on_role_id"
    t.index ["tenant_id", "user_id", "role_id"], name: "index_assignments_on_tenant_id_and_user_id_and_role_id", unique: true
    t.index ["tenant_id"], name: "index_assignments_on_tenant_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.integer "break_minutes", default: 0, null: false
    t.datetime "clock_in_at"
    t.datetime "clock_out_at"
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.text "note"
    t.integer "overtime_minutes", default: 0, null: false
    t.string "status", default: "draft", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.date "work_date", null: false
    t.integer "work_shift_id"
    t.integer "worked_minutes", default: 0, null: false
    t.index ["employee_id"], name: "index_attendance_records_on_employee_id"
    t.index ["tenant_id", "employee_id", "work_date"], name: "idx_on_tenant_id_employee_id_work_date_c1b98dbfd2", unique: true
    t.index ["tenant_id", "status"], name: "index_attendance_records_on_tenant_id_and_status"
    t.index ["tenant_id", "work_date"], name: "index_attendance_records_on_tenant_id_and_work_date"
    t.index ["tenant_id"], name: "index_attendance_records_on_tenant_id"
    t.index ["work_shift_id"], name: "index_attendance_records_on_work_shift_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action"
    t.string "action_key", null: false
    t.bigint "actor_id"
    t.string "actor_type"
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.string "http_method"
    t.string "ip_address"
    t.text "metadata"
    t.string "path"
    t.string "request_id"
    t.string "status", default: "succeeded", null: false
    t.string "summary"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.index ["action_key"], name: "index_audit_logs_on_action_key"
    t.index ["actor_type", "actor_id"], name: "index_audit_logs_on_actor_type_and_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["request_id"], name: "index_audit_logs_on_request_id"
    t.index ["tenant_id"], name: "index_audit_logs_on_tenant_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "billing_batches", force: :cascade do |t|
    t.string "batch_number", null: false
    t.date "billing_period_from", null: false
    t.date "billing_period_to", null: false
    t.datetime "cancelled_at"
    t.integer "cancelled_by_id"
    t.date "closing_date", null: false
    t.datetime "created_at", null: false
    t.integer "customer_count", default: 0, null: false
    t.date "default_due_date"
    t.datetime "executed_at"
    t.integer "executed_by_id"
    t.integer "invoice_count", default: 0, null: false
    t.date "invoice_date", null: false
    t.text "note"
    t.string "status", default: "issued", null: false
    t.integer "tenant_id", null: false
    t.decimal "total_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["cancelled_by_id"], name: "index_billing_batches_on_cancelled_by_id"
    t.index ["executed_by_id"], name: "index_billing_batches_on_executed_by_id"
    t.index ["tenant_id", "batch_number"], name: "index_billing_batches_on_tenant_id_and_batch_number", unique: true
    t.index ["tenant_id", "billing_period_from", "billing_period_to"], name: "idx_on_tenant_id_billing_period_from_billing_period_ccd1591ff1"
    t.index ["tenant_id", "closing_date"], name: "index_billing_batches_on_tenant_id_and_closing_date"
    t.index ["tenant_id"], name: "index_billing_batches_on_tenant_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2
    t.boolean "auto_renewal", default: false, null: false
    t.string "contract_number", null: false
    t.string "counterparty_type", default: "other", null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.text "description"
    t.date "ended_on"
    t.text "note"
    t.date "started_on", null: false
    t.string "status", default: "draft", null: false
    t.bigint "supplier_id"
    t.bigint "tenant_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_contracts_on_customer_id"
    t.index ["supplier_id"], name: "index_contracts_on_supplier_id"
    t.index ["tenant_id", "contract_number"], name: "index_contracts_on_tenant_id_and_contract_number", unique: true
    t.index ["tenant_id", "ended_on"], name: "index_contracts_on_tenant_id_and_ended_on"
    t.index ["tenant_id", "status"], name: "index_contracts_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_contracts_on_tenant_id"
  end

  create_table "customer_inquiries", force: :cascade do |t|
    t.integer "assigned_user_id"
    t.string "company_name"
    t.string "contact_email"
    t.string "contact_person_department"
    t.string "contact_person_name"
    t.string "contact_tel"
    t.datetime "created_at", null: false
    t.integer "customer_id"
    t.text "details"
    t.date "inquiry_date", null: false
    t.string "inquiry_number", null: false
    t.date "response_due_date"
    t.string "source", default: "email", null: false
    t.string "status", default: "new", null: false
    t.string "subject", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_user_id"], name: "index_customer_inquiries_on_assigned_user_id"
    t.index ["customer_id"], name: "index_customer_inquiries_on_customer_id"
    t.index ["tenant_id", "inquiry_date"], name: "index_customer_inquiries_on_tenant_id_and_inquiry_date"
    t.index ["tenant_id", "inquiry_number"], name: "index_customer_inquiries_on_tenant_id_and_inquiry_number", unique: true
    t.index ["tenant_id", "status"], name: "index_customer_inquiries_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_customer_inquiries_on_tenant_id"
  end

  create_table "customer_opportunities", force: :cascade do |t|
    t.decimal "actual_sales_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "assigned_user_id"
    t.date "closed_on"
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.integer "customer_inquiry_id"
    t.decimal "expected_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.date "expected_close_on"
    t.text "next_action"
    t.date "opened_on", null: false
    t.string "opportunity_number", null: false
    t.integer "probability", default: 0, null: false
    t.string "stage", default: "hearing", null: false
    t.string "subject", null: false
    t.text "summary"
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_user_id"], name: "index_customer_opportunities_on_assigned_user_id"
    t.index ["customer_id"], name: "index_customer_opportunities_on_customer_id"
    t.index ["customer_inquiry_id"], name: "index_customer_opportunities_on_customer_inquiry_id"
    t.index ["tenant_id", "opened_on"], name: "index_customer_opportunities_on_tenant_id_and_opened_on"
    t.index ["tenant_id", "opportunity_number"], name: "idx_on_tenant_id_opportunity_number_6dece9cd92", unique: true
    t.index ["tenant_id", "stage"], name: "index_customer_opportunities_on_tenant_id_and_stage"
    t.index ["tenant_id"], name: "index_customer_opportunities_on_tenant_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.integer "closing_day"
    t.string "code", null: false
    t.string "contact_person_department"
    t.string "contact_person_email"
    t.string "contact_person_name"
    t.string "contact_person_tel"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "invoice_delivery_method"
    t.string "name", null: false
    t.string "name_kana"
    t.text "note"
    t.string "payment_due_rule"
    t.string "payment_method"
    t.string "postal_code"
    t.string "status", default: "active", null: false
    t.string "tel"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "code"], name: "index_customers_on_tenant_id_and_code", unique: true
    t.index ["tenant_id", "status"], name: "index_customers_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_customers_on_tenant_id"
  end

  create_table "daily_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.text "notes"
    t.date "report_date", null: false
    t.integer "site_id", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.text "work_content", null: false
    t.decimal "work_hours", precision: 5, scale: 2, null: false
    t.index ["employee_id"], name: "index_daily_reports_on_employee_id"
    t.index ["site_id"], name: "index_daily_reports_on_site_id"
    t.index ["tenant_id", "employee_id"], name: "index_daily_reports_on_tenant_id_and_employee_id"
    t.index ["tenant_id", "report_date"], name: "index_daily_reports_on_tenant_id_and_report_date"
    t.index ["tenant_id", "site_id"], name: "index_daily_reports_on_tenant_id_and_site_id"
    t.index ["tenant_id"], name: "index_daily_reports_on_tenant_id"
  end

  create_table "deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.string "delivery_address"
    t.date "delivery_date", null: false
    t.string "delivery_number", null: false
    t.datetime "issued_at"
    t.bigint "order_id", null: false
    t.text "remarks"
    t.string "status", default: "issued", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_deliveries_on_customer_id"
    t.index ["order_id"], name: "index_deliveries_on_order_id"
    t.index ["tenant_id", "delivery_number"], name: "index_deliveries_on_tenant_id_and_delivery_number", unique: true
    t.index ["tenant_id"], name: "index_deliveries_on_tenant_id"
  end

  create_table "delivery_items", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "delivered_quantity", null: false
    t.bigint "delivery_id", null: false
    t.bigint "order_item_id", null: false
    t.string "product_code_snapshot", null: false
    t.bigint "product_id", null: false
    t.string "product_name_snapshot", null: false
    t.bigint "tenant_id", null: false
    t.string "unit_name_snapshot", null: false
    t.decimal "unit_price", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id"], name: "index_delivery_items_on_delivery_id"
    t.index ["order_item_id"], name: "index_delivery_items_on_order_item_id"
    t.index ["product_id"], name: "index_delivery_items_on_product_id"
    t.index ["tenant_id"], name: "index_delivery_items_on_tenant_id"
  end

  create_table "document_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "document_type", null: false
    t.text "settings"
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "document_type"], name: "index_document_templates_on_tenant_id_and_document_type", unique: true
    t.index ["tenant_id"], name: "index_document_templates_on_tenant_id"
  end

  create_table "employees", force: :cascade do |t|
    t.decimal "base_hourly_wage", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "base_monthly_salary", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "default_break_minutes", default: 60, null: false
    t.string "email"
    t.string "employee_code", null: false
    t.string "employment_type", default: "hourly", null: false
    t.date "joined_on"
    t.string "name", null: false
    t.text "note"
    t.decimal "overtime_rate_multiplier", precision: 5, scale: 2, default: "1.25", null: false
    t.decimal "paid_leave_granted_days", precision: 5, scale: 1, default: "10.0", null: false
    t.integer "standard_daily_minutes", default: 480, null: false
    t.string "status", default: "active", null: false
    t.string "tel"
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "employee_code"], name: "index_employees_on_tenant_id_and_employee_code", unique: true
    t.index ["tenant_id", "status"], name: "index_employees_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_employees_on_tenant_id"
  end

  create_table "expense_reports", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.string "category", default: "other", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.bigint "employee_id", null: false
    t.date "expensed_on", null: false
    t.text "note"
    t.text "purpose"
    t.string "status", default: "pending", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_expense_reports_on_employee_id"
    t.index ["tenant_id", "employee_id", "expensed_on"], name: "idx_expense_reports_on_tenant_employee_date"
    t.index ["tenant_id", "status"], name: "index_expense_reports_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_expense_reports_on_tenant_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "invoice_id", null: false
    t.integer "quantity", null: false
    t.bigint "source_id"
    t.string "source_type"
    t.string "tax_category", default: "taxable_10", null: false
    t.bigint "tenant_id", null: false
    t.decimal "unit_price", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["source_type", "source_id"], name: "index_invoice_items_on_source"
    t.index ["tenant_id", "source_type", "source_id"], name: "index_invoice_items_on_tenant_and_source"
    t.index ["tenant_id"], name: "index_invoice_items_on_tenant_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.decimal "balance_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "billing_batch_id"
    t.date "billing_period_from", null: false
    t.date "billing_period_to", null: false
    t.datetime "cancelled_at"
    t.date "closing_date", null: false
    t.integer "closing_day_snapshot"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.date "due_date", null: false
    t.date "invoice_date", null: false
    t.string "invoice_delivery_method_snapshot"
    t.string "invoice_number", null: false
    t.decimal "paid_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.string "payment_due_rule_snapshot"
    t.integer "reissued_from_id"
    t.text "remarks"
    t.string "status", default: "issued", null: false
    t.decimal "subtotal_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.bigint "tenant_id", null: false
    t.decimal "total_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["billing_batch_id"], name: "index_invoices_on_billing_batch_id"
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["reissued_from_id"], name: "index_invoices_on_reissued_from_id"
    t.index ["tenant_id", "invoice_number"], name: "index_invoices_on_tenant_id_and_invoice_number", unique: true
    t.index ["tenant_id"], name: "index_invoices_on_tenant_id"
  end

  create_table "leave_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "days_count", precision: 5, scale: 1, default: "1.0", null: false
    t.integer "employee_id", null: false
    t.date "end_date", null: false
    t.string "half_day_type", default: "none", null: false
    t.string "leave_type", default: "paid_leave", null: false
    t.text "note"
    t.text "reason"
    t.date "start_date", null: false
    t.string "status", default: "pending", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_leave_requests_on_employee_id"
    t.index ["tenant_id", "employee_id", "start_date"], name: "idx_on_tenant_id_employee_id_start_date_fca66a23f0"
    t.index ["tenant_id", "status"], name: "index_leave_requests_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_leave_requests_on_tenant_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "line_no", null: false
    t.bigint "order_id", null: false
    t.string "product_code_snapshot", null: false
    t.bigint "product_id", null: false
    t.string "product_name_snapshot", null: false
    t.integer "quantity", null: false
    t.string "status", default: "pending", null: false
    t.string "tax_category_snapshot", default: "taxable_10", null: false
    t.bigint "tenant_id", null: false
    t.string "unit_name_snapshot", null: false
    t.decimal "unit_price", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "line_no"], name: "index_order_items_on_order_id_and_line_no", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["tenant_id"], name: "index_order_items_on_tenant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.string "delivery_address"
    t.date "order_date", null: false
    t.string "order_number", null: false
    t.string "ordered_by_name"
    t.integer "quotation_id"
    t.text "remarks"
    t.date "requested_delivery_date"
    t.datetime "sent_at"
    t.string "status", default: "draft", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["quotation_id"], name: "index_orders_on_quotation_id"
    t.index ["tenant_id", "order_number"], name: "index_orders_on_tenant_id_and_order_number", unique: true
    t.index ["tenant_id"], name: "index_orders_on_tenant_id"
  end

  create_table "payment_allocations", force: :cascade do |t|
    t.decimal "allocated_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "allocated_at", null: false
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.bigint "payment_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payment_allocations_on_invoice_id"
    t.index ["payment_id", "invoice_id"], name: "index_payment_allocations_on_payment_id_and_invoice_id", unique: true
    t.index ["payment_id"], name: "index_payment_allocations_on_payment_id"
    t.index ["tenant_id"], name: "index_payment_allocations_on_tenant_id"
  end

  create_table "payments", force: :cascade do |t|
    t.string "account_name"
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.string "bank_name"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.date "payment_date", null: false
    t.string "payment_method"
    t.string "payment_number", null: false
    t.string "reference_note"
    t.string "status", default: "pending", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_payments_on_customer_id"
    t.index ["tenant_id", "payment_number"], name: "index_payments_on_tenant_id_and_payment_number", unique: true
    t.index ["tenant_id"], name: "index_payments_on_tenant_id"
  end

  create_table "payroll_entries", force: :cascade do |t|
    t.decimal "base_pay", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.decimal "gross_pay", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "overtime_minutes", default: 0, null: false
    t.decimal "overtime_pay", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "paid_leave_days", precision: 5, scale: 1, default: "0.0", null: false
    t.decimal "paid_leave_pay", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "payroll_run_id", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "worked_minutes", default: 0, null: false
    t.index ["employee_id"], name: "index_payroll_entries_on_employee_id"
    t.index ["payroll_run_id", "employee_id"], name: "index_payroll_entries_on_payroll_run_id_and_employee_id", unique: true
    t.index ["payroll_run_id"], name: "index_payroll_entries_on_payroll_run_id"
    t.index ["tenant_id", "employee_id"], name: "index_payroll_entries_on_tenant_id_and_employee_id"
    t.index ["tenant_id"], name: "index_payroll_entries_on_tenant_id"
  end

  create_table "payroll_runs", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.integer "confirmed_by_id"
    t.datetime "created_at", null: false
    t.integer "employee_count", default: 0, null: false
    t.datetime "generated_at"
    t.integer "generated_by_id"
    t.text "note"
    t.date "payroll_month", null: false
    t.string "run_number", null: false
    t.string "status", default: "generated", null: false
    t.integer "tenant_id", null: false
    t.decimal "total_gross_pay", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_by_id"], name: "index_payroll_runs_on_confirmed_by_id"
    t.index ["generated_by_id"], name: "index_payroll_runs_on_generated_by_id"
    t.index ["tenant_id", "payroll_month"], name: "index_payroll_runs_on_tenant_id_and_payroll_month", unique: true
    t.index ["tenant_id", "run_number"], name: "index_payroll_runs_on_tenant_id_and_run_number", unique: true
    t.index ["tenant_id"], name: "index_payroll_runs_on_tenant_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.string "name", null: false
    t.string "resource", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_permissions_on_key", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "note"
    t.decimal "standard_price", precision: 14, scale: 2, default: "0.0", null: false
    t.string "tax_category", default: "taxable_10", null: false
    t.bigint "tenant_id", null: false
    t.string "unit_name", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "code"], name: "index_products_on_tenant_id_and_code", unique: true
    t.index ["tenant_id"], name: "index_products_on_tenant_id"
  end

  create_table "purchase_adjustments", force: :cascade do |t|
    t.date "adjustment_date", null: false
    t.string "adjustment_number", null: false
    t.string "adjustment_type", null: false
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "issued_at"
    t.string "processed_by_name"
    t.string "product_code_snapshot"
    t.integer "product_id"
    t.string "product_name_snapshot"
    t.integer "purchase_order_id", null: false
    t.integer "purchase_receipt_id", null: false
    t.integer "purchase_receipt_item_id"
    t.integer "quantity", default: 0, null: false
    t.text "reason"
    t.string "status", default: "issued", null: false
    t.integer "supplier_id", null: false
    t.integer "tenant_id", null: false
    t.decimal "unit_cost", precision: 14, scale: 2, default: "0.0", null: false
    t.string "unit_name_snapshot"
    t.datetime "updated_at", null: false
    t.integer "warehouse_id", null: false
    t.index ["product_id"], name: "index_purchase_adjustments_on_product_id"
    t.index ["purchase_order_id"], name: "index_purchase_adjustments_on_purchase_order_id"
    t.index ["purchase_receipt_id"], name: "index_purchase_adjustments_on_purchase_receipt_id"
    t.index ["purchase_receipt_item_id"], name: "index_purchase_adjustments_on_purchase_receipt_item_id"
    t.index ["supplier_id"], name: "index_purchase_adjustments_on_supplier_id"
    t.index ["tenant_id", "adjustment_date"], name: "index_purchase_adjustments_on_tenant_id_and_adjustment_date"
    t.index ["tenant_id", "adjustment_number"], name: "index_purchase_adjustments_on_tenant_id_and_adjustment_number", unique: true
    t.index ["tenant_id", "adjustment_type"], name: "index_purchase_adjustments_on_tenant_id_and_adjustment_type"
    t.index ["tenant_id"], name: "index_purchase_adjustments_on_tenant_id"
    t.index ["warehouse_id"], name: "index_purchase_adjustments_on_warehouse_id"
  end

  create_table "purchase_bill_batches", force: :cascade do |t|
    t.string "batch_number", null: false
    t.integer "bill_count", default: 0, null: false
    t.date "bill_date", null: false
    t.date "billing_period_from", null: false
    t.date "billing_period_to", null: false
    t.datetime "cancelled_at"
    t.integer "cancelled_by_id"
    t.date "closing_date", null: false
    t.datetime "created_at", null: false
    t.date "default_due_date"
    t.datetime "executed_at"
    t.integer "executed_by_id"
    t.text "note"
    t.string "status", default: "issued", null: false
    t.integer "supplier_count", default: 0, null: false
    t.integer "tenant_id", null: false
    t.decimal "total_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["cancelled_by_id"], name: "index_purchase_bill_batches_on_cancelled_by_id"
    t.index ["executed_by_id"], name: "index_purchase_bill_batches_on_executed_by_id"
    t.index ["tenant_id", "batch_number"], name: "index_purchase_bill_batches_on_tenant_id_and_batch_number", unique: true
    t.index ["tenant_id", "billing_period_from", "billing_period_to"], name: "idx_on_tenant_id_billing_period_from_billing_period_0255e1340b"
    t.index ["tenant_id", "closing_date"], name: "index_purchase_bill_batches_on_tenant_id_and_closing_date"
    t.index ["tenant_id"], name: "index_purchase_bill_batches_on_tenant_id"
  end

  create_table "purchase_bill_items", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "purchase_bill_id", null: false
    t.integer "quantity", null: false
    t.integer "source_id"
    t.string "source_type"
    t.string "tax_category", default: "taxable_10", null: false
    t.integer "tenant_id", null: false
    t.decimal "unit_price", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_bill_id"], name: "index_purchase_bill_items_on_purchase_bill_id"
    t.index ["source_type", "source_id"], name: "index_purchase_bill_items_on_source"
    t.index ["tenant_id", "source_type", "source_id"], name: "idx_on_tenant_id_source_type_source_id_75db0218e4"
    t.index ["tenant_id"], name: "index_purchase_bill_items_on_tenant_id"
  end

  create_table "purchase_bills", force: :cascade do |t|
    t.decimal "balance_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.date "bill_date", null: false
    t.string "bill_number", null: false
    t.date "billing_period_from", null: false
    t.date "billing_period_to", null: false
    t.datetime "cancelled_at"
    t.date "closing_date", null: false
    t.integer "closing_day_snapshot"
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.decimal "paid_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.string "payment_due_rule_snapshot"
    t.string "payment_method_snapshot"
    t.integer "purchase_bill_batch_id"
    t.integer "reissued_from_id"
    t.text "remarks"
    t.string "status", default: "issued", null: false
    t.decimal "subtotal_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "supplier_id", null: false
    t.decimal "tax_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "tenant_id", null: false
    t.decimal "total_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_bill_batch_id"], name: "index_purchase_bills_on_purchase_bill_batch_id"
    t.index ["reissued_from_id"], name: "index_purchase_bills_on_reissued_from_id"
    t.index ["supplier_id"], name: "index_purchase_bills_on_supplier_id"
    t.index ["tenant_id", "bill_date"], name: "index_purchase_bills_on_tenant_id_and_bill_date"
    t.index ["tenant_id", "bill_number"], name: "index_purchase_bills_on_tenant_id_and_bill_number", unique: true
    t.index ["tenant_id", "status"], name: "index_purchase_bills_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_purchase_bills_on_tenant_id"
  end

  create_table "purchase_order_items", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "line_no", null: false
    t.string "product_code_snapshot", null: false
    t.integer "product_id", null: false
    t.string "product_name_snapshot", null: false
    t.integer "purchase_order_id", null: false
    t.integer "quantity", null: false
    t.integer "received_quantity", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.string "tax_category_snapshot", default: "taxable_10", null: false
    t.integer "tenant_id", null: false
    t.decimal "unit_cost", precision: 14, scale: 2, default: "0.0", null: false
    t.string "unit_name_snapshot", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_order_items_on_product_id"
    t.index ["purchase_order_id", "line_no"], name: "index_purchase_order_items_on_purchase_order_id_and_line_no", unique: true
    t.index ["purchase_order_id"], name: "index_purchase_order_items_on_purchase_order_id"
    t.index ["tenant_id"], name: "index_purchase_order_items_on_tenant_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "order_date", null: false
    t.string "ordered_by_name"
    t.string "purchase_order_number", null: false
    t.text "remarks"
    t.date "requested_delivery_date"
    t.datetime "sent_at"
    t.string "status", default: "draft", null: false
    t.integer "supplier_id", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "warehouse_id", null: false
    t.index ["supplier_id"], name: "index_purchase_orders_on_supplier_id"
    t.index ["tenant_id", "order_date"], name: "index_purchase_orders_on_tenant_id_and_order_date"
    t.index ["tenant_id", "purchase_order_number"], name: "index_purchase_orders_on_tenant_id_and_purchase_order_number", unique: true
    t.index ["tenant_id", "status"], name: "index_purchase_orders_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_purchase_orders_on_tenant_id"
    t.index ["warehouse_id"], name: "index_purchase_orders_on_warehouse_id"
  end

  create_table "purchase_receipt_items", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "product_code_snapshot", null: false
    t.integer "product_id", null: false
    t.string "product_name_snapshot", null: false
    t.integer "purchase_order_item_id", null: false
    t.integer "purchase_receipt_id", null: false
    t.integer "received_quantity", null: false
    t.integer "tenant_id", null: false
    t.decimal "unit_cost", precision: 14, scale: 2, default: "0.0", null: false
    t.string "unit_name_snapshot", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_receipt_items_on_product_id"
    t.index ["purchase_order_item_id"], name: "index_purchase_receipt_items_on_purchase_order_item_id"
    t.index ["purchase_receipt_id"], name: "index_purchase_receipt_items_on_purchase_receipt_id"
    t.index ["tenant_id"], name: "index_purchase_receipt_items_on_tenant_id"
  end

  create_table "purchase_receipts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "issued_at"
    t.integer "purchase_order_id", null: false
    t.string "purchase_receipt_number", null: false
    t.string "received_by_name"
    t.date "received_on", null: false
    t.text "remarks"
    t.string "status", default: "issued", null: false
    t.integer "supplier_id", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "warehouse_id", null: false
    t.index ["purchase_order_id"], name: "index_purchase_receipts_on_purchase_order_id"
    t.index ["supplier_id"], name: "index_purchase_receipts_on_supplier_id"
    t.index ["tenant_id", "purchase_receipt_number"], name: "idx_on_tenant_id_purchase_receipt_number_631b1eb1c2", unique: true
    t.index ["tenant_id", "received_on"], name: "index_purchase_receipts_on_tenant_id_and_received_on"
    t.index ["tenant_id"], name: "index_purchase_receipts_on_tenant_id"
    t.index ["warehouse_id"], name: "index_purchase_receipts_on_warehouse_id"
  end

  create_table "quotation_items", force: :cascade do |t|
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "line_no", null: false
    t.string "product_code_snapshot", null: false
    t.integer "product_id", null: false
    t.string "product_name_snapshot", null: false
    t.integer "quantity", null: false
    t.integer "quotation_id", null: false
    t.string "tax_category_snapshot", default: "taxable_10", null: false
    t.integer "tenant_id", null: false
    t.string "unit_name_snapshot", null: false
    t.decimal "unit_price", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_quotation_items_on_product_id"
    t.index ["quotation_id", "line_no"], name: "index_quotation_items_on_quotation_id_and_line_no", unique: true
    t.index ["quotation_id"], name: "index_quotation_items_on_quotation_id"
    t.index ["tenant_id"], name: "index_quotation_items_on_tenant_id"
  end

  create_table "quotations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "converted_at"
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.date "expiration_date", null: false
    t.date "quotation_date", null: false
    t.string "quotation_number", null: false
    t.string "quoted_by_name"
    t.text "remarks"
    t.datetime "sent_at"
    t.string "status", default: "draft", null: false
    t.string "subject"
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_quotations_on_customer_id"
    t.index ["tenant_id", "quotation_date"], name: "index_quotations_on_tenant_id_and_quotation_date"
    t.index ["tenant_id", "quotation_number"], name: "index_quotations_on_tenant_id_and_quotation_number", unique: true
    t.index ["tenant_id", "status"], name: "index_quotations_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_quotations_on_tenant_id"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.boolean "allowed", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.boolean "built_in", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "description"
    t.string "key", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "key"], name: "index_roles_on_tenant_id_and_key", unique: true
    t.index ["tenant_id"], name: "index_roles_on_tenant_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "address"
    t.string "category", default: "construction", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.string "name", null: false
    t.integer "progress_percentage", default: 0, null: false
    t.date "start_date"
    t.string "status", default: "active", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "code"], name: "index_sites_on_tenant_id_and_code", unique: true
    t.index ["tenant_id", "status"], name: "index_sites_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_sites_on_tenant_id"
  end

  create_table "stock_allocations", force: :cascade do |t|
    t.datetime "allocated_at", null: false
    t.integer "allocated_quantity", null: false
    t.datetime "created_at", null: false
    t.bigint "order_item_id", null: false
    t.bigint "product_id", null: false
    t.datetime "released_at"
    t.string "status", default: "reserved", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["order_item_id"], name: "index_stock_allocations_on_order_item_id"
    t.index ["product_id"], name: "index_stock_allocations_on_product_id"
    t.index ["tenant_id", "order_item_id"], name: "index_stock_allocations_on_tenant_id_and_order_item_id"
    t.index ["tenant_id"], name: "index_stock_allocations_on_tenant_id"
    t.index ["warehouse_id"], name: "index_stock_allocations_on_warehouse_id"
  end

  create_table "stock_counts", force: :cascade do |t|
    t.integer "adjustment_quantity", default: 0, null: false
    t.datetime "counted_at", null: false
    t.integer "counted_quantity", null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.integer "product_id", null: false
    t.integer "quantity_before", null: false
    t.integer "stock_item_id", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "warehouse_id", null: false
    t.index ["product_id"], name: "index_stock_counts_on_product_id"
    t.index ["stock_item_id"], name: "index_stock_counts_on_stock_item_id"
    t.index ["tenant_id", "counted_at"], name: "index_stock_counts_on_tenant_id_and_counted_at"
    t.index ["tenant_id"], name: "index_stock_counts_on_tenant_id"
    t.index ["warehouse_id"], name: "index_stock_counts_on_warehouse_id"
  end

  create_table "stock_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "quantity_on_hand", default: 0, null: false
    t.integer "quantity_reserved", default: 0, null: false
    t.integer "safety_stock", default: 0, null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["product_id"], name: "index_stock_items_on_product_id"
    t.index ["tenant_id", "warehouse_id", "product_id"], name: "index_stock_items_on_tenant_id_and_warehouse_id_and_product_id", unique: true
    t.index ["tenant_id"], name: "index_stock_items_on_tenant_id"
    t.index ["warehouse_id"], name: "index_stock_items_on_warehouse_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "movement_type", null: false
    t.text "note"
    t.date "occurred_on", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.bigint "reference_id"
    t.string "reference_type"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["reference_type", "reference_id"], name: "index_stock_movements_on_reference"
    t.index ["tenant_id", "occurred_on"], name: "index_stock_movements_on_tenant_id_and_occurred_on"
    t.index ["tenant_id"], name: "index_stock_movements_on_tenant_id"
    t.index ["warehouse_id"], name: "index_stock_movements_on_warehouse_id"
  end

  create_table "supplier_payment_allocations", force: :cascade do |t|
    t.decimal "allocated_amount", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "allocated_at"
    t.datetime "created_at", null: false
    t.integer "purchase_bill_id", null: false
    t.integer "supplier_payment_id", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_bill_id"], name: "index_supplier_payment_allocations_on_purchase_bill_id"
    t.index ["supplier_payment_id", "purchase_bill_id"], name: "index_supplier_payment_allocations_on_payment_and_bill", unique: true
    t.index ["supplier_payment_id"], name: "index_supplier_payment_allocations_on_supplier_payment_id"
    t.index ["tenant_id"], name: "index_supplier_payment_allocations_on_tenant_id"
  end

  create_table "supplier_payments", force: :cascade do |t|
    t.string "account_name"
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.string "bank_name"
    t.datetime "created_at", null: false
    t.date "payment_date", null: false
    t.string "payment_method"
    t.string "payment_number", null: false
    t.string "reference_note"
    t.string "status", default: "pending", null: false
    t.integer "supplier_id", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "index_supplier_payments_on_supplier_id"
    t.index ["tenant_id", "payment_date"], name: "index_supplier_payments_on_tenant_id_and_payment_date"
    t.index ["tenant_id", "payment_number"], name: "index_supplier_payments_on_tenant_id_and_payment_number", unique: true
    t.index ["tenant_id", "status"], name: "index_supplier_payments_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_supplier_payments_on_tenant_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.integer "closing_day"
    t.string "code", null: false
    t.string "contact_person_department"
    t.string "contact_person_email"
    t.string "contact_person_name"
    t.string "contact_person_tel"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "name_kana"
    t.text "note"
    t.string "payment_due_rule"
    t.string "payment_method"
    t.string "postal_code"
    t.string "status", default: "active", null: false
    t.string "tel"
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "code"], name: "index_suppliers_on_tenant_id_and_code", unique: true
    t.index ["tenant_id", "status"], name: "index_suppliers_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_suppliers_on_tenant_id"
  end

  create_table "tenant_user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "primary_flag", default: false, null: false
    t.bigint "role_id", null: false
    t.bigint "tenant_user_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_tenant_user_roles_on_role_id"
    t.index ["tenant_user_id", "role_id"], name: "index_tenant_user_roles_on_tenant_user_id_and_role_id", unique: true
    t.index ["tenant_user_id"], name: "index_tenant_user_roles_on_tenant_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.integer "billing_closing_day"
    t.string "billing_email", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "industry", default: "general", null: false
    t.string "invoice_registration_number"
    t.string "name", null: false
    t.integer "payroll_closing_day"
    t.string "plan", null: false
    t.integer "purchase_closing_day"
    t.string "status", null: false
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tenants_on_code", unique: true
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "primary", default: false, null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.datetime "deleted_at"
    t.string "email", null: false
    t.integer "employee_id"
    t.string "encrypted_password", default: "", null: false
    t.boolean "initial_flag", default: true, null: false
    t.boolean "is_owner", default: false, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "line_id"
    t.string "locale"
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.bigint "tenant_id", null: false
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["employee_id"], name: "index_users_on_employee_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tenant_id", "email"], name: "index_users_on_tenant_id_and_email", unique: true
    t.index ["tenant_id", "line_id"], name: "index_users_on_tenant_id_and_line_id"
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "code"], name: "index_warehouses_on_tenant_id_and_code", unique: true
    t.index ["tenant_id"], name: "index_warehouses_on_tenant_id"
  end

  create_table "work_shifts", force: :cascade do |t|
    t.integer "break_minutes", default: 60, null: false
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.time "end_time", null: false
    t.text "note"
    t.time "start_time", null: false
    t.string "status", default: "scheduled", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.date "work_date", null: false
    t.index ["employee_id"], name: "index_work_shifts_on_employee_id"
    t.index ["tenant_id", "employee_id", "work_date"], name: "index_work_shifts_on_tenant_id_and_employee_id_and_work_date", unique: true
    t.index ["tenant_id", "work_date"], name: "index_work_shifts_on_tenant_id_and_work_date"
    t.index ["tenant_id"], name: "index_work_shifts_on_tenant_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assignments", "roles"
  add_foreign_key "assignments", "tenants"
  add_foreign_key "assignments", "users"
  add_foreign_key "attendance_records", "employees"
  add_foreign_key "attendance_records", "tenants"
  add_foreign_key "attendance_records", "work_shifts"
  add_foreign_key "audit_logs", "tenants"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "billing_batches", "tenants"
  add_foreign_key "billing_batches", "users", column: "cancelled_by_id"
  add_foreign_key "billing_batches", "users", column: "executed_by_id"
  add_foreign_key "contracts", "customers"
  add_foreign_key "contracts", "suppliers"
  add_foreign_key "contracts", "tenants"
  add_foreign_key "customer_inquiries", "customers"
  add_foreign_key "customer_inquiries", "tenants"
  add_foreign_key "customer_inquiries", "users", column: "assigned_user_id"
  add_foreign_key "customer_opportunities", "customer_inquiries"
  add_foreign_key "customer_opportunities", "customers"
  add_foreign_key "customer_opportunities", "tenants"
  add_foreign_key "customer_opportunities", "users", column: "assigned_user_id"
  add_foreign_key "customers", "tenants"
  add_foreign_key "daily_reports", "employees"
  add_foreign_key "daily_reports", "sites"
  add_foreign_key "daily_reports", "tenants"
  add_foreign_key "deliveries", "customers"
  add_foreign_key "deliveries", "orders"
  add_foreign_key "deliveries", "tenants"
  add_foreign_key "delivery_items", "deliveries"
  add_foreign_key "delivery_items", "order_items"
  add_foreign_key "delivery_items", "products"
  add_foreign_key "delivery_items", "tenants"
  add_foreign_key "document_templates", "tenants"
  add_foreign_key "employees", "tenants"
  add_foreign_key "expense_reports", "employees"
  add_foreign_key "expense_reports", "tenants"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "tenants"
  add_foreign_key "invoices", "billing_batches"
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "invoices", column: "reissued_from_id"
  add_foreign_key "invoices", "tenants"
  add_foreign_key "leave_requests", "employees"
  add_foreign_key "leave_requests", "tenants"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_items", "tenants"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "quotations"
  add_foreign_key "orders", "tenants"
  add_foreign_key "payment_allocations", "invoices"
  add_foreign_key "payment_allocations", "payments"
  add_foreign_key "payment_allocations", "tenants"
  add_foreign_key "payments", "customers"
  add_foreign_key "payments", "tenants"
  add_foreign_key "payroll_entries", "employees"
  add_foreign_key "payroll_entries", "payroll_runs"
  add_foreign_key "payroll_entries", "tenants"
  add_foreign_key "payroll_runs", "tenants"
  add_foreign_key "payroll_runs", "users", column: "generated_by_id"
  add_foreign_key "products", "tenants"
  add_foreign_key "purchase_adjustments", "products"
  add_foreign_key "purchase_adjustments", "purchase_orders"
  add_foreign_key "purchase_adjustments", "purchase_receipt_items"
  add_foreign_key "purchase_adjustments", "purchase_receipts"
  add_foreign_key "purchase_adjustments", "suppliers"
  add_foreign_key "purchase_adjustments", "tenants"
  add_foreign_key "purchase_adjustments", "warehouses"
  add_foreign_key "purchase_bill_batches", "tenants"
  add_foreign_key "purchase_bill_batches", "users", column: "cancelled_by_id"
  add_foreign_key "purchase_bill_batches", "users", column: "executed_by_id"
  add_foreign_key "purchase_bill_items", "purchase_bills"
  add_foreign_key "purchase_bill_items", "tenants"
  add_foreign_key "purchase_bills", "purchase_bill_batches"
  add_foreign_key "purchase_bills", "purchase_bills", column: "reissued_from_id"
  add_foreign_key "purchase_bills", "suppliers"
  add_foreign_key "purchase_bills", "tenants"
  add_foreign_key "purchase_order_items", "products"
  add_foreign_key "purchase_order_items", "purchase_orders"
  add_foreign_key "purchase_order_items", "tenants"
  add_foreign_key "purchase_orders", "suppliers"
  add_foreign_key "purchase_orders", "tenants"
  add_foreign_key "purchase_orders", "warehouses"
  add_foreign_key "purchase_receipt_items", "products"
  add_foreign_key "purchase_receipt_items", "purchase_order_items"
  add_foreign_key "purchase_receipt_items", "purchase_receipts"
  add_foreign_key "purchase_receipt_items", "tenants"
  add_foreign_key "purchase_receipts", "purchase_orders"
  add_foreign_key "purchase_receipts", "suppliers"
  add_foreign_key "purchase_receipts", "tenants"
  add_foreign_key "purchase_receipts", "warehouses"
  add_foreign_key "quotation_items", "products"
  add_foreign_key "quotation_items", "quotations"
  add_foreign_key "quotation_items", "tenants"
  add_foreign_key "quotations", "customers"
  add_foreign_key "quotations", "tenants"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "roles", "tenants"
  add_foreign_key "sites", "tenants"
  add_foreign_key "stock_allocations", "order_items"
  add_foreign_key "stock_allocations", "products"
  add_foreign_key "stock_allocations", "tenants"
  add_foreign_key "stock_allocations", "warehouses"
  add_foreign_key "stock_counts", "products"
  add_foreign_key "stock_counts", "stock_items"
  add_foreign_key "stock_counts", "tenants"
  add_foreign_key "stock_counts", "warehouses"
  add_foreign_key "stock_items", "products"
  add_foreign_key "stock_items", "tenants"
  add_foreign_key "stock_items", "warehouses"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "tenants"
  add_foreign_key "stock_movements", "warehouses"
  add_foreign_key "supplier_payment_allocations", "purchase_bills"
  add_foreign_key "supplier_payment_allocations", "supplier_payments"
  add_foreign_key "supplier_payment_allocations", "tenants"
  add_foreign_key "supplier_payments", "suppliers"
  add_foreign_key "supplier_payments", "tenants"
  add_foreign_key "suppliers", "tenants"
  add_foreign_key "tenant_user_roles", "roles"
  add_foreign_key "tenant_user_roles", "users", column: "tenant_user_id"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "employees"
  add_foreign_key "users", "tenants"
  add_foreign_key "warehouses", "tenants"
  add_foreign_key "work_shifts", "employees"
  add_foreign_key "work_shifts", "tenants"
end
