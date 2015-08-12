require_relative 'abstract_controller'
require_relative '../command_objects/update_calibration'

module FBPi
  class UpdateCalibrationController < AbstractController
    def call
      reply "calibrate_axis",
            UpdateCalibration.run!(bot: bot, settings: message.params)
    end
  end
end
