# Builds a validated sequence (and collection of steps)
require_relative '../models/sequence'

class SequenceFactory < Mutations::Command
  required do
    string :name
    array(:steps) { model :step, builder: StepFactory }
  end

  def execute
    Sequence.create!(inputs)
  end
end
