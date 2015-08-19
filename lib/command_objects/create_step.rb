require_relative '../models/step'
module FBPi
  # Factory for new step objects. Mostly used when pulling down steps from the
  # Web App's API and transforming that JSON data into SQLite/ActiveRecord
  # objects
  class CreateStep < Mutations::Command
    required do
      string :message_type, in: Step::COMMANDS
      integer :position
      hash :command do
        optional do
          integer :x,               default: nil
          integer :y,               default: nil
          integer :z,               default: nil
          integer :speed,           default: nil
          integer :pin,             default: nil
          integer :mode,            default: nil
          string  :variable,        default: nil
          string  :operator,        default: nil
          string  :sub_sequence_id, default: nil
          string  :value,           default: nil
        end
      end
    end

    def execute
      Step.new(inputs.merge(inputs["command"]))
    end
  end
end
