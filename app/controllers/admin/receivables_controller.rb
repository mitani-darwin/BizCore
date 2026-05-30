module Admin
  # 売掛残高一覧を表示する読み取り専用コントローラ。得意先ごとに未回収請求の集計を表示する。
  class ReceivablesController < BaseController
    def index
      @filters = {
        q: search_keyword,
        status: search_status,
        balance_scope: search_balance_scope,
        as_of: as_of_date
      }

      customers = current_tenant.customers
                                .includes(:invoices)
                                .search(search_keyword)
                                .with_status(search_status)
                                .ordered_for_admin
      all_rows = build_rows(customers)
      @summary = {
        count: all_rows.size,
        unpaid_invoice_count: all_rows.sum { |row| row[:unpaid_invoice_count] },
        outstanding_amount: all_rows.sum { |row| row[:outstanding_amount] },
        overdue_invoice_count: all_rows.sum { |row| row[:overdue_invoice_count] },
        overdue_amount: all_rows.sum { |row| row[:overdue_amount] }
      }
      @pagy, @receivable_rows = pagy_array(all_rows)
    end

    private

    def build_rows(customers)
      customers.filter_map do |customer|
        outstanding_amount = customer.outstanding_invoice_amount
        overdue_amount = customer.overdue_invoice_amount(as_of: as_of_date)
        next if skip_row?(outstanding_amount, overdue_amount)

        {
          customer: customer,
          unpaid_invoice_count: customer.unpaid_invoice_count,
          outstanding_amount: outstanding_amount,
          overdue_invoice_count: customer.overdue_invoice_count(as_of: as_of_date),
          overdue_amount: overdue_amount,
          aging: customer.receivable_aging(as_of: as_of_date),
          last_invoice_date: customer.last_invoice_date
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
      Customer.statuses.value?(status) ? status : nil
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
