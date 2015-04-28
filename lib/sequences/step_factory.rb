class StepFactory < Mutations::Command
  COMMANDS = %w(emergency_stop home_all home_x home_y home_z move_absolute
    move_relative pin_write read_parameter read_status write_parameter)

  required do
    string :message_type, in: COMMANDS
    hash :command do
      optional do
        [:x, :y, :z, :speed, :pin, :value, :mode].each do |f|
          integer f, default: nil
        end
      end
    end
  end

  def execute
    Step.new(inputs)
  end
end
