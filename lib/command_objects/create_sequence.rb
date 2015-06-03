# Builds a validated sequence (and collection of steps)
require_relative '../models/sequence'
# Was called SequenceFactory at one point
class CreateSequence < Mutations::Command
  required do
    string :name
    array(:steps) { model :step, builder: CreateStep, new_records: true }
  end

  def execute
    Sequence.new(inputs)
  end
end
