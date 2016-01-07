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
          integer :movement_timeout_x
          integer :movement_timeout_y
          integer :movement_timeout_z
          integer :movement_invert_endpoints_x
          integer :movement_invert_endpoints_y
          integer :movement_invert_endpoints_z
          integer :movement_invert_motor_x
          integer :movement_invert_motor_y
          integer :movement_invert_motor_z
          integer :movement_steps_acc_dec_x
          integer :movement_steps_acc_dec_y
          integer :movement_steps_acc_dec_z
          integer :movement_home_up_x
          integer :movement_home_up_y
          integer :movement_home_up_z
          integer :movement_min_spd_x
          integer :movement_min_spd_y
          integer :movement_min_spd_z
          integer :movement_max_spd_x
          integer :movement_max_spd_y
          integer :movement_max_spd_z
        end
      end
    end

    def execute
      settings.each do |key, param_value|
        key = key.upcase
        param_number = PARAMETER_DICTIONARY[key.to_sym]

        if bot.status.to_h[key.to_sym] != param_value
          # TODO: This belongs inside of write_parameter
          bot.status.transaction { |i| i[key] = param_value }
          bot.commands.write_parameter(param_number, param_value)
        end
      end

      ReportBotStatus.run!(bot: bot)
    end
  end
end

