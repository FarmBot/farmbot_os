require 'mutations'

module FBPi
  # Responsible for setting calibration settings for a specific axis. Required
  # when changing settings like speed, accelerations, steps_per_mm, etc.
  class UpdateCalibration < Mutations::Command
    PARAMETER_DICTIONARY = FB::Gcode::PARAMETER_DICTIONARY.invert

    required do
      duck :bot, methods: [:commands]
      hash :settings do
        optional do
          integer :MOVEMENT_TIMEOUT_X
          integer :MOVEMENT_TIMEOUT_Y
          integer :MOVEMENT_TIMEOUT_Z
          integer :MOVEMENT_INVERT_ENDPOINTS_X
          integer :MOVEMENT_INVERT_ENDPOINTS_Y
          integer :MOVEMENT_INVERT_ENDPOINTS_Z
          integer :MOVEMENT_INVERT_MOTOR_X
          integer :MOVEMENT_INVERT_MOTOR_Y
          integer :MOVEMENT_INVERT_MOTOR_Z
          integer :MOVEMENT_STEPS_ACC_DEC_X
          integer :MOVEMENT_STEPS_ACC_DEC_Y
          integer :MOVEMENT_STEPS_ACC_DEC_Z
          integer :MOVEMENT_HOME_UP_X
          integer :MOVEMENT_HOME_UP_Y
          integer :MOVEMENT_HOME_UP_Z
          integer :MOVEMENT_MIN_SPD_X
          integer :MOVEMENT_MIN_SPD_Y
          integer :MOVEMENT_MIN_SPD_Z
          integer :MOVEMENT_MAX_SPD_X
          integer :MOVEMENT_MAX_SPD_Y
          integer :MOVEMENT_MAX_SPD_Z
        end
      end
    end

    def execute
      settings.each do |key, param_value|
        param_number = PARAMETER_DICTIONARY[key.to_sym]
        if bot.status.to_h[key.to_sym] != param_value
          # TODO: This belongs inside of write_parameter
          bot.status.transaction { |i| i[key] = param_value }
          bot.commands.write_parameter(param_number, param_value)
        end
      end
    end
  end
end

