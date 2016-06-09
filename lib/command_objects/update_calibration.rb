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
          # Possible values:
          # param_version, movement_timeout_x, movement_timeout_y, movement_timeout_z,
          # movement_invert_endpoints_x, movement_invert_endpoints_y, movement_invert_endpoints_z,
          # movement_invert_motor_x, movement_invert_motor_y, movement_invert_motor_z,
          # movement_steps_acc_dec_x, movement_steps_acc_dec_y, movement_steps_acc_dec_z,
          # movement_home_up_x, movement_home_up_y, movement_home_up_z, movement_min_spd_x,
          # movement_min_spd_y, movement_min_spd_z, movement_max_spd_x, movement_max_spd_y, movement_max_spd_z,
          # encoder_enabled_x, encoder_enabled_y, encoder_enabled_z, encoder_missed_steps_max_x,
          # encoder_missed_steps_max_y, encoder_missed_steps_max_z, encoder_missed_steps_decay_x,
          # encoder_missed_steps_decay_y, encoder_missed_steps_decay_z, movement_axis_nr_steps_x,
          # movement_axis_nr_steps_y, movement_axis_nr_steps_z, pin_guard_1_pin_nr, pin_guard_1_time_out,
          # pin_guard_1_active_state, pin_guard_2_pin_nr, pin_guard_2_time_out, pin_guard_2_active_state,
          # pin_guard_3_pin_nr, pin_guard_3_time_out, pin_guard_3_active_state, pin_guard_4_pin_nr,
          # pin_guard_4_time_out, pin_guard_4_active_state, pin_guard_5_pin_nr, pin_guard_5_time_out,
          # pin_guard_5_active_state
          PARAMETER_DICTIONARY.keys.map(&:downcase).each { |p| integer(p) }
        end
      end
    end

    def execute
      settings.each do |key, param_value|
        key = key.upcase
        param_number = PARAMETER_DICTIONARY[key.to_sym]

        if bot.status.to_h[key.to_sym] != param_value
          # TODO: This belongs inside of write_parameter
          # TODO: Move this into farmbot-serial and send PR.
          bot.status.transaction { |i| i[key] = param_value }
          bot.commands.write_parameter(param_number, param_value)
        end
      end

      ReportBotStatus.run!(bot: bot)
    end
  end
end

