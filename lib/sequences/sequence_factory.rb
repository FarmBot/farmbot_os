# Builds a validated sequence (and collection of steps)
require_relative '../models/sequence'

class SequenceFactory < Mutations::Command
  required do
    string :name
    array(:steps) { model :step, builder: StepFactory, new_records: true }
  end

  def execute
    Sequence.new(inputs)
  end
end
