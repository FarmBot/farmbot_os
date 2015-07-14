require_relative '../models/step'
# Once named 'StepFactory'
module FBPi
  class CreateStep < Mutations::Command
    required do
      string :message_type, in: Step::COMMANDS
      integer :position
      hash :command do
        optional do
          [:x, :y, :z, :speed, :pin, :mode].each do |f|
            integer f, default: nil
          end
          string :value, default: nil
        end
      end
    end

    def execute
      Step.new(inputs.merge(inputs["command"]))
    end
  end
end
