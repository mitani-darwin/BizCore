module Admin
  # 従業員ごとの有給残日数一覧を表示する読み取り専用コントローラ。
  class LeaveBalancesController < BaseController
    def index
      @as_of = parse_date(params[:as_of]) || Date.current
      @filters = {
        q:             params[:q].to_s.strip,
        status:        search_status,
        balance_scope: search_balance_scope,
        as_of:         @as_of
      }

      employees = current_tenant.employees
                                .includes(:leave_requests)
                                .search(@filters[:q])
                                .with_status(@filters[:status].presence || "active")
                                .ordered_for_admin

      @balance_rows = build_rows(employees)
      apply_balance_scope!

      @summary = {
        employee_count: @balance_rows.size,
        total_granted:  @balance_rows.sum { |r| r[:granted_days] },
        total_used:     @balance_rows.sum { |r| r[:used_days] },
        total_remaining: @balance_rows.sum { |r| r[:remaining_days] }
      }
      @pagy, @balance_rows = pagy(@balance_rows)
    end

    private

    def build_rows(employees)
      employees.map do |employee|
        used_days = employee.leave_requests
                            .select { |lr| lr.status == "approved" && lr.leave_type == "paid_leave" && lr.start_date <= @as_of }
                            .sum { |lr| lr.days_count.to_d }
        granted   = employee.paid_leave_granted_days.to_d
        remaining = granted - used_days

        {
          employee:      employee,
          granted_days:  granted,
          used_days:     used_days,
          remaining_days: remaining
        }
      end
    end

    def apply_balance_scope!
      @balance_rows = case @filters[:balance_scope]
      when "positive"        then @balance_rows.select { |r| r[:remaining_days] > 0 }
      when "zero_or_less"    then @balance_rows.select { |r| r[:remaining_days] <= 0 }
      else @balance_rows
      end
    end

    def search_status
      status = params[:status].to_s
      Employee.statuses.value?(status) ? status : nil
    end

    def search_balance_scope
      scope = params[:balance_scope].to_s
      %w[all positive zero_or_less].include?(scope) ? scope : "all"
    end

    def parse_date(raw_value)
      return nil if raw_value.blank?

      Date.iso8601(raw_value)
    rescue ArgumentError
      nil
    end
  end
end
