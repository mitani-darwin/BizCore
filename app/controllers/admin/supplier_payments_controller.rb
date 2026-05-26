module Admin
  class SupplierPaymentsController < BaseController
    before_action :set_supplier_payment, only: [ :show, :edit, :update, :reconcile ]
    before_action :set_source_purchase_bill, only: [ :new, :create ]
    before_action :set_supplier_options, only: [ :new, :create, :edit, :update ]

    def index
      @pagy, @supplier_payments = pagy(current_tenant.supplier_payments.includes(:supplier, :supplier_payment_allocations).order(payment_date: :desc, id: :desc))
    end

    def show
      prepare_reconciliation_context
    end

    def new
      @supplier_payment = current_tenant.supplier_payments.build(new_payment_defaults)
    end

    def create
      @supplier_payment = current_tenant.supplier_payments.build(supplier_payment_params)

      if persist_supplier_payment_with_optional_source_allocation
        message = @source_purchase_bill ? "支払を登録し、仕入請求へ消し込みました。" : "支払を登録しました。"
        redirect_to admin_supplier_payment_path(@supplier_payment), notice: message
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @supplier_payment.update(supplier_payment_params)
        redirect_to admin_supplier_payment_path(@supplier_payment), notice: "支払情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def reconcile
      allocations = build_allocations
      raise ArgumentError, "消し込み金額を入力してください" if allocations.empty?

      Purchases::ReconcileSupplierPayment.call(supplier_payment: @supplier_payment, allocations: allocations)
      audit!(
        action_key: required_permission_key,
        auditable: @supplier_payment,
        metadata: { allocations: allocations.map { |entry| { purchase_bill_id: entry[:purchase_bill].id, amount: entry[:amount] } } }
      )
      redirect_to admin_supplier_payment_path(@supplier_payment), notice: "支払を消し込みました。"
    rescue StandardError => e
      redirect_to admin_supplier_payment_path(@supplier_payment), alert: "消し込みに失敗しました: #{e.message}"
    end

    private

    def set_supplier_payment
      @supplier_payment = current_tenant.supplier_payments.includes(:supplier, supplier_payment_allocations: :purchase_bill).find_by(id: params[:id])
      return if @supplier_payment

      render_not_found and return false
    end

    def set_supplier_options
      @supplier_options = current_tenant.suppliers.order(:name)
    end

    def set_source_purchase_bill
      purchase_bill_id = params[:source_purchase_bill_id].presence
      return if purchase_bill_id.blank?

      purchase_bill = current_tenant.purchase_bills.includes(:supplier).find_by(id: purchase_bill_id)
      return if purchase_bill.nil?
      return unless purchase_bill.outstanding_amount.positive?
      return if purchase_bill.cancelled?

      @source_purchase_bill = purchase_bill
    end

    def supplier_payment_params
      params.require(:supplier_payment).permit(
        :supplier_id,
        :payment_date,
        :amount,
        :payment_method,
        :bank_name,
        :account_name,
        :reference_note
      )
    end

    def new_payment_defaults
      defaults = {
        payment_date: Date.current,
        payment_method: "bank_transfer"
      }
      return defaults unless @source_purchase_bill

      defaults.merge(
        supplier: @source_purchase_bill.supplier,
        amount: @source_purchase_bill.outstanding_amount,
        reference_note: "#{@source_purchase_bill.bill_number} から登録"
      )
    end

    def persist_supplier_payment_with_optional_source_allocation
      ActiveRecord::Base.transaction do
        return false unless @supplier_payment.save

        apply_source_purchase_bill_allocation! if @source_purchase_bill
      end

      true
    rescue StandardError => e
      @supplier_payment.errors.add(:base, e.message)
      false
    end

    def apply_source_purchase_bill_allocation!
      raise ArgumentError, "仕入請求と異なる仕入先の支払は登録できません" if @supplier_payment.supplier_id != @source_purchase_bill.supplier_id

      allocation_amount = [ @supplier_payment.amount.to_d, @source_purchase_bill.outstanding_amount ].min
      return if allocation_amount <= 0

      Purchases::ReconcileSupplierPayment.call(
        supplier_payment: @supplier_payment,
        allocations: [ { purchase_bill: @source_purchase_bill, amount: allocation_amount } ]
      )
    end

    def prepare_reconciliation_context
      @reconcilable_purchase_bills = current_tenant.purchase_bills.where(supplier: @supplier_payment.supplier).where(status: %w[issued partially_paid]).where("balance_amount > 0").order(:due_date, :bill_date, :id)
      @supplier_payment_allocations = @supplier_payment.supplier_payment_allocations.includes(:purchase_bill).order(:allocated_at, :id)
    end

    def build_allocations
      purchase_bills = current_tenant.purchase_bills.where(supplier: @supplier_payment.supplier).index_by(&:id)
      params.fetch(:allocations, {}).to_unsafe_h.each_with_object([]) do |(purchase_bill_id, raw_amount), result|
        amount = raw_amount.to_d
        next if amount <= 0

        purchase_bill = purchase_bills[purchase_bill_id.to_i]
        next if purchase_bill.nil?

        result << { purchase_bill: purchase_bill, amount: amount }
      end
    end
  end
end
