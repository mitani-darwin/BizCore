module Payrolls
  # 月次給与計算を実行するサービス。
  # 同月の既存 PayrollRun がある場合は上書き再生成する（確定済みは例外）。
  # insert_all! でバルクインサートして N+1 を回避する。
  # 月給制は base_monthly_salary 固定、時給制は実労働時間 × 時給で算出する。
  class GenerateRun
    # テナントの全従業員について当月分の PayrollRun と PayrollEntry を生成して返す。
    def self.call(tenant:, payroll_month:, requested_by:, note: nil)
      new(tenant:, payroll_month:, requested_by:, note:).call
    end

    def initialize(tenant:, payroll_month:, requested_by:, note:)
      @tenant = tenant
      @payroll_month = payroll_month.beginning_of_month
      @requested_by = requested_by
      @note = note
    end

    def call
      PayrollRun.transaction do
        run = tenant.payroll_runs.find_or_initialize_by(payroll_month: payroll_month)
        raise "確定済みの給与計算は再生成できません" if run.confirmed?

        run.generated_by = requested_by
        run.generated_at = Time.current
        run.status = "generated"
        run.note = note
        run.confirmed_at = nil
        run.confirmed_by = nil
        run.save!

        run.payroll_entries.delete_all

        entries = tenant.employees.ordered_for_admin.map do |employee|
          build_entry(run:, employee:)
        end

        PayrollEntry.insert_all!(entries) if entries.any?

        run.reload
        run.update!(
          employee_count: run.payroll_entries.count,
          total_gross_pay: run.payroll_entries.sum(:gross_pay)
        )
        run
      end
    end

    private

    attr_reader :tenant, :payroll_month, :requested_by, :note

    def build_entry(run:, employee:)
      attendances = employee.attendance_records.where(work_date: period_range).where(status: "closed")
      worked_minutes = attendances.sum(:worked_minutes).to_i
      overtime_minutes = attendances.sum(:overtime_minutes).to_i
      regular_minutes = [ worked_minutes - overtime_minutes, 0 ].max
      paid_leave_days = approved_paid_leave_days(employee)

      base_pay =
        if employee.employment_type_salaried? && employee.base_monthly_salary.to_d.positive?
          employee.base_monthly_salary.to_d
        else
          hourly_amount(employee.effective_hourly_rate, regular_minutes)
        end

      overtime_pay = hourly_amount(employee.effective_hourly_rate * employee.overtime_rate_multiplier.to_d, overtime_minutes)
      paid_leave_pay =
        if employee.employment_type_hourly?
          employee.effective_hourly_rate * employee.standard_daily_hours * paid_leave_days
        else
          0.to_d
        end

      gross_pay = base_pay + overtime_pay + paid_leave_pay

      {
        tenant_id: tenant.id,
        payroll_run_id: run.id,
        employee_id: employee.id,
        worked_minutes: worked_minutes,
        overtime_minutes: overtime_minutes,
        paid_leave_days: paid_leave_days,
        base_pay: base_pay,
        overtime_pay: overtime_pay,
        paid_leave_pay: paid_leave_pay,
        gross_pay: gross_pay,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    def period_range
      payroll_month.beginning_of_month..payroll_month.end_of_month
    end

    def hourly_amount(rate, minutes)
      rate.to_d * (minutes.to_d / 60)
    end

    def approved_paid_leave_days(employee)
      employee.leave_requests
              .approved_paid_leave
              .where("start_date <= ? AND end_date >= ?", period_range.end, period_range.begin)
              .to_a
              .sum { |leave_request| leave_request.days_within(period_range) }
              .to_d
    end
  end
end
