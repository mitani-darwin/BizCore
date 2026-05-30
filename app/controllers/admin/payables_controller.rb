module Admin
  # 買掛残高一覧を表示する読み取り専用コントローラ。ReceivablesController の仕入側に対応する。
  class PayablesController < BaseController
    def index
      @filters = {
        q: search_keyword,
        status: search_status,
        balance_scope: search_balance_scope,
        as_of: as_of_date
      }

      suppliers = current_tenant.suppliers
                                .includes(:purchase_bills, :supplier_payments)
                                .search(search_keyword)
                                .with_status(search_status)
                                .ordered_for_admin
      all_rows = build_rows(suppliers)
      @summary = {
        count: all_rows.size,
        unpaid_purchase_bill_count: all_rows.sum { |row| row[:unpaid_purchase_bill_count] },
        outstanding_amount: all_rows.sum { |row| row[:outstanding_amount] },
        overdue_purchase_bill_count: all_rows.sum { |row| row[:overdue_purchase_bill_count] },
        overdue_amount: all_rows.sum { |row| row[:overdue_amount] }
      }
      @pagy, @payable_rows = pagy_array(all_rows)
    end

    private

    def build_rows(suppliers)
      suppliers.filter_map do |supplier|
        outstanding_amount = supplier.outstanding_purchase_bill_amount
        overdue_amount = supplier.overdue_purchase_bill_amount(as_of: as_of_date)
        next if skip_row?(outstanding_amount, overdue_amount)

        {
          supplier: supplier,
          unpaid_purchase_bill_count: supplier.unpaid_purchase_bill_count,
          outstanding_amount: outstanding_amount,
          overdue_purchase_bill_count: supplier.overdue_purchase_bill_count(as_of: as_of_date),
          overdue_amount: overdue_amount,
          aging: supplier.payable_aging(as_of: as_of_date),
          last_purchase_bill_date: supplier.last_purchase_bill_date
        }
      end
    end

    def skip_row?(outstanding_amount, overdue_amount)
      case search_balance_scope
      when "open"
        outstanding_amount <= 0
      when "overdue"
        overdue_amount <= 0
      else
        false
      end
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      status = params[:status].to_s
      Supplier.statuses.value?(status) ? status : nil
    end

    def search_balance_scope
      scope = params[:balance_scope].to_s
      %w[all open overdue].include?(scope) ? scope : "all"
    end

    def as_of_date
      @as_of_date ||= parse_date!(params[:as_of], default: Date.current)
    end

    def parse_date!(raw_value, default:)
      return default if raw_value.blank?

      Date.iso8601(raw_value)
    rescue ArgumentError
      raise ArgumentError, "日付の形式が正しくありません"
    end
  end
end
