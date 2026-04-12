module Admin
  class CollectionSchedulesController < BaseController
    def index
      @filters = {
        q: search_keyword,
        status: search_status,
        schedule_scope: search_schedule_scope,
        as_of: as_of_date
      }

      invoices = current_tenant.invoices
                               .includes(:customer)
                               .joins(:customer)
                               .merge(Customer.search(search_keyword))
                               .merge(Customer.with_status(search_status))
                               .where(status: %w[issued partially_paid])
                               .where("invoices.balance_amount > 0")
                               .order(:due_date, :invoice_date, :id)
      @collection_schedule_rows = build_rows(invoices)
      @summary = build_summary(@collection_schedule_rows)
    end

    private

    def build_rows(invoices)
      invoices.filter_map do |invoice|
        next unless schedule_scope_match?(invoice.due_date)

        {
          invoice: invoice,
          customer: invoice.customer,
          due_date: invoice.due_date,
          outstanding_amount: invoice.outstanding_amount,
          days_delta: (invoice.due_date - as_of_date).to_i
        }
      end
    end

    def build_summary(rows)
      {
        count: rows.size,
        total_amount: rows.sum { |row| row[:outstanding_amount] },
        overdue_count: rows.count { |row| row[:days_delta].negative? },
        overdue_amount: rows.select { |row| row[:days_delta].negative? }.sum { |row| row[:outstanding_amount] },
        due_today_count: rows.count { |row| row[:days_delta].zero? },
        due_today_amount: rows.select { |row| row[:days_delta].zero? }.sum { |row| row[:outstanding_amount] },
        due_within_7_days_amount: rows.select { |row| row[:days_delta].between?(0, 7) }.sum { |row| row[:outstanding_amount] }
      }
    end

    def schedule_scope_match?(due_date)
      days_delta = (due_date - as_of_date).to_i

      case search_schedule_scope
      when "overdue"
        days_delta.negative?
      when "today"
        days_delta.zero?
      when "within_7_days"
        days_delta.between?(0, 7)
      when "within_30_days"
        days_delta.between?(0, 30)
      else
        true
      end
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      status = params[:status].to_s
      Customer.statuses.value?(status) ? status : nil
    end

    def search_schedule_scope
      scope = params[:schedule_scope].to_s
      %w[all overdue today within_7_days within_30_days].include?(scope) ? scope : "all"
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
