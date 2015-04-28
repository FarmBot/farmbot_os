# Builds a validated sequence (and collection of steps)
class SequenceFactory < Mutations::Command
  required do
    string :name
    array(:steps) { model :step, builder: StepFactory }
  end

  def execute
    OpenStruct.new(inputs)
  end
end
