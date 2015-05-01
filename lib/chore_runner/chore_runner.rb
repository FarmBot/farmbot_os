class ChoreRunner
  INTERVAL = 60 # seconds
  attr_accessor :jobs

  def fetch_schedules
    a = Schedule.where(next_time: nil).to_a # Never executed
    b = Schedule.where("next_time < ?", Time.now).to_a # Overdue
    a + b # both
  end

  def run
    # TODO: Don't crash when scheduled jobs raise.
    (@jobs = fetch_schedules).present? ? something : nothing
  end

  def something
    # TODO: Bot#log.
    puts "Running #{@jobs.count} jobs."
    jobs.each(&:run_now)
    @jobs = []
  end

  def nothing
    # TODO: Bot#log.
    puts "Nothing to run this cycle. Waiting an additional #{INTERVAL} secs."
  end
end
