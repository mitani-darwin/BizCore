module Attendances
  # 月次勤怠締め処理を実行するサービス。
  # 「working」ステータスの打刻中レコードを退勤打刻なしのまま「closed」に移行する。
  # 「draft」（打刻なし）はそのまま残し、closed_count/already_closed_count/draft_count を Result で返す。
  class CloseMonth
    # 処理結果サマリーを保持する値オブジェクト。
    Result = Struct.new(:closed_count, :already_closed_count, :draft_count, keyword_init: true)

    def self.call(tenant:, month:, requested_by:)
      new(tenant:, month:, requested_by:).call
    end

    def initialize(tenant:, month:, requested_by:)
      @tenant = tenant
      @month = month.beginning_of_month
      @requested_by = requested_by
    end

    def call
      records = tenant.attendance_records.for_month(month)
      already_closed_count = records.where(status: "closed").count
      draft_count          = records.where(status: "draft").count
      working_records      = records.where(status: "working").includes(:work_shift, :employee)

      closed_count = 0
      AttendanceRecord.transaction do
        working_records.find_each do |record|
          record.update!(clock_out_at: determine_clock_out(record))
          closed_count += 1
        end
      end

      Result.new(closed_count: closed_count, already_closed_count: already_closed_count, draft_count: draft_count)
    end

    private

    attr_reader :tenant, :month, :requested_by

    def determine_clock_out(record)
      candidate = raw_candidate(record)
      candidate > record.clock_in_at ? candidate : record.clock_in_at + 30.minutes
    end

    def raw_candidate(record)
      work_date = record.work_date

      if (shift_end = record.work_shift&.end_time)
        # シフト終了時刻を勤務日の同時刻として構築
        Time.zone.local(work_date.year, work_date.month, work_date.day, shift_end.hour, shift_end.min)
      elsif record.employee.standard_daily_minutes.to_i > 0
        record.clock_in_at + record.employee.standard_daily_minutes.minutes
      else
        record.clock_in_at + 8.hours
      end
    end
  end
end
