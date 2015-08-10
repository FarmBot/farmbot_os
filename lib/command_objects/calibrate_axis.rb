require 'mutations'

module FBPi
  # Responsible for setting calibration settings for a specific axis. Required
  # when changing settings like speed, accelerations, steps_per_mm, etc.
  class CalibrateAxis < Mutations::Command
    required do
      duck :bot, methods: [:commands]
      string :axis, in: %w( x y z )
      hash :settings do
        optional do
          integer :max_speed       # steps
          integer :acceleration    # mm
          integer :timeout         # Seconds
          boolean :end_inversion
          boolean :motor_inversion
        end
      end
    end

    def execute
      settings.each { |key, val| bot.commands.send("set_#{key}", axis, val) }
    end
  end
end

