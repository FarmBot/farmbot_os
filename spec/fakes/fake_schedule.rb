class FakeSchedule
  def end_time
    Time.now + 1.hour
  end

  def time_unit
    'hourly'
  end

  def repeat
    1
  end

  def sequence
    @sequence ||= FakeSequence.new
  end

  def update_attributes(_)
    self
  end
end
