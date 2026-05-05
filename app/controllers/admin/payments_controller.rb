module Admin
  class PaymentsController < BaseController
    before_action :set_payment, only: [ :show, :edit, :update, :reconcile ]
    before_action :set_source_invoice, only: [ :new, :create ]
    before_action :set_customer_options, only: [ :new, :create, :edit, :update ]

    def index
      @payments = current_tenant.payments.includes(:customer, :payment_allocations).order(payment_date: :desc, id: :desc)
    end

    def show
      prepare_reconciliation_context
    end

    def new
      @payment = current_tenant.payments.build(new_payment_defaults)
    end

    def create
      @payment = current_tenant.payments.build(payment_params)

      if persist_payment_with_optional_source_allocation
        message = @source_invoice ? "入金を登録し、請求へ消し込みました。" : "入金を登録しました。"
        redirect_to admin_payment_path(@payment), notice: message
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @payment.update(payment_params)
        redirect_to admin_payment_path(@payment), notice: "入金情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def reconcile
      allocations = build_allocations
      raise ArgumentError, "消し込み金額を入力してください" if allocations.empty?

      Payments::ReconcilePayment.call(payment: @payment, allocations: allocations)
      audit!(action_key: required_permission_key, auditable: @payment, metadata: { allocations: allocations.map { |entry| { invoice_id: entry[:invoice].id, amount: entry[:amount] } } })
      redirect_to admin_payment_path(@payment), notice: "入金を消し込みました。"
    rescue StandardError => e
      redirect_to admin_payment_path(@payment), alert: "消し込みに失敗しました: #{e.message}"
    end

    private

    def set_payment
      @payment = current_tenant.payments.includes(:customer, payment_allocations: :invoice).find_by(id: params[:id])
      return if @payment

      render_not_found and return false
    end

    def set_customer_options
      @customer_options = current_tenant.customers.order(:name)
    end

    def set_source_invoice
      invoice_id = params[:source_invoice_id].presence
      return if invoice_id.blank?

      invoice = current_tenant.invoices.includes(:customer).find_by(id: invoice_id)
      return if invoice.nil?
      return unless invoice.balance_amount.to_d.positive?
      return if invoice.cancelled?

      @source_invoice = invoice
    end

    def payment_params
      params.require(:payment).permit(
        :customer_id,
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
      return defaults unless @source_invoice

      defaults.merge(
        customer: @source_invoice.customer,
        amount: @source_invoice.outstanding_amount,
        reference_note: "#{@source_invoice.invoice_number} から登録"
      )
    end

    def persist_payment_with_optional_source_allocation
      ActiveRecord::Base.transaction do
        return false unless @payment.save

        apply_source_invoice_allocation! if @source_invoice
      end

      true
    rescue StandardError => e
      @payment.errors.add(:base, e.message)
      false
    end

    def apply_source_invoice_allocation!
      raise ArgumentError, "請求と異なる得意先の入金は登録できません" if @payment.customer_id != @source_invoice.customer_id

      allocation_amount = [ @payment.amount.to_d, @source_invoice.outstanding_amount ].min
      return if allocation_amount <= 0

      Payments::ReconcilePayment.call(
        payment: @payment,
        allocations: [ { invoice: @source_invoice, amount: allocation_amount } ]
      )
    end

    def prepare_reconciliation_context
      @reconcilable_invoices = current_tenant.invoices.where(customer: @payment.customer).where(status: %w[issued partially_paid]).where("balance_amount > 0").order(:due_date, :invoice_date, :id)
      @payment_allocations = @payment.payment_allocations.includes(:invoice).order(:allocated_at, :id)
    end

    def build_allocations
      invoices = current_tenant.invoices.where(customer: @payment.customer).index_by(&:id)
      params.fetch(:allocations, {}).to_unsafe_h.each_with_object([]) do |(invoice_id, raw_amount), result|
        amount = raw_amount.to_d
        next if amount <= 0

        invoice = invoices[invoice_id.to_i]
        next if invoice.nil?

        result << { invoice: invoice, amount: amount }
      end
    end
  end
end
