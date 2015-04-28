require_relative 'abstract_controller'
require_relative '../sequence_factory'
class ExecSequenceController < AbstractController
  def call
    sequence = SequenceFactory.run!(Hash(@message.payload["command"]))
    sequence.steps.each do |step|
      step.call(bot)
    end
    reply "exec_sequence"
  rescue Mutations::ValidationException => error
    reply "error", error: error.message
  end
end
