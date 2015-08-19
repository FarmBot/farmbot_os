require_relative 'abstract_controller'
require_relative '../command_objects/update_calibration'

module FBPi
  # Used to remotely set one of the many possible "parameter" variables inside
  # of the Arduino. Useful for calibration. SEE: FBPi::UpdateCalibration
  class UpdateCalibrationController < AbstractController
    def call
      reply "calibrate_axis",
            UpdateCalibration.run!(bot: bot, settings: message.params)
    end
  end
end
