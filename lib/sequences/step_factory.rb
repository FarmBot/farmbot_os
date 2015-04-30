require_relative '../models/step'

class StepFactory < Mutations::Command
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
    Step.create!(inputs.merge(inputs["command"]))
  end
end




