require 'spec_helper'

describe FBPi::UpdateCalibration do
  let(:bot) { FakeBot.new }

  it "handles known calibration params" do
   known = {MOVEMENT_TIMEOUT_X: 123}
   parameter_code = FB::Gcode::PARAMETER_DICTIONARY.invert[:MOVEMENT_TIMEOUT_X]
   allow(bot.commands).to receive(:write_parameter).with(parameter_code, 123)
   FBPi::UpdateCalibration.run!(bot: bot, settings: known)
   expect(bot.commands).to have_received(:write_parameter)
  end

  it "handles unknown calibration params" do
  end
end
