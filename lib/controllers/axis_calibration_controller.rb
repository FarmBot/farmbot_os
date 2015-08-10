require_relative 'abstract_controller'
require_relative '../command_objects/calibrate_axis'

module FBPi
  class AxisCalibrationController < AbstractController
    def call
      reply "calibrate_axis", raise("Not done yet")
    end
  end
end
