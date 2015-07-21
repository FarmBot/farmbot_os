class Sequence < ActiveRecord::Base
  has_many :schedules
  has_many :steps, dependent: :destroy

  def exec(bot)
    steps
      .sort{ |a, b| a.position <=> b.position}
      .map { |step| step.execute(bot) }
  end
end
