require_relative '../models/step'
# Once named 'StepFactory'
module FBPi
  class CreateStep < Mutations::Command
    required do
      string :message_type, in: Step::COMMANDS
      hash :command do
        optional do
          [:x, :y, :z, :speed, :pin, :value, :mode].each do |f|
            integer f, default: nil
          end
        end
      end
    end

    def execute
      Step.new(inputs.merge(inputs["command"]))
    end
  end
end
