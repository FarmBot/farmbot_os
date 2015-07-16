# Builds a validated sequence (and collection of steps)
require_relative '../models/sequence'
# Was called SequenceFactory at one point

module FBPi
  class CreateSequence < Mutations::Command
    required do
      string :name
      string :_id
      array(:steps) { model :step, builder: CreateStep, new_records: true }
    end

    def execute

      Sequence.new(inputs.merge!(id_on_web_app: inputs.delete(:_id)))
    end
  end
end
