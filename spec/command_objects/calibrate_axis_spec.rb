require 'spec_helper'

describe FBPi::IfStatement do
  let(:bot) { FakeBot.new }

  it "changes calibration settings" do
    random_inputs = {
      max_speed:       rand(1000),
      acceleration:    rand(1000),
      timeout:         rand(1000),
      end_inversion:   [true, false].sample,
      motor_inversion: [true, false].sample,
    }
    random_inputs.each do |key, val|
      axis = %w(x y z).sample
      allow(bot.commands).to receive("set_#{key}")
      FBPi::CalibrateAxis.run!(bot: bot,
                               settings: {key => val},
                               axis: axis)
      expect(bot.commands).to have_received("set_#{key}").with(axis, val)
    end
  end
end
