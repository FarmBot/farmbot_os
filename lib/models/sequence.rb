class Sequence < ActiveRecord::Base
  has_many :schedules
  has_many :steps, dependent: :destroy

  def exec(bot)
    steps
      .sort{ |a, b| a.position <=> b.position}
      .map { |step| FBPi::ExecStep.run!(bot: bot, step: step) }
  end
end
