# Builds a validated sequence (and collection of steps)
require_relative 'sequence'

class SequenceFactory < Mutations::Command
  required do
    string :name
    array(:steps) { model :step, builder: StepFactory }
  end

  def execute
    Sequence.new(inputs)
  end
end
