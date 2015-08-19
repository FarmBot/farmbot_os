require_relative '../models/sequence'

module FBPi
  # Builds a validated sequence (a collection of steps that the bot will
  # execute, eg: "Plant tomato seeds")
  class CreateSequence < Mutations::Command
    required do
      string :name
      string :_id
      array(:steps) { model :step, builder: CreateStep, new_records: true }
    end

    def execute
      Sequence.create!(inputs.merge!(id_on_web_app: inputs.delete(:_id)))
    end
  end
end
