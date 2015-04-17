require_relative 'abstract_controller'
require_relative '../sequence_factory'
class ExecSequenceController < AbstractController
  def call
    sequence = SequenceFactory.run!(@message.payload["command"])
    sequence.steps.each { |s| s.call(bot) }
    reply "exec_sequence", {wow: '123'}
  rescue Mutations::ValidationException => error
    reply "error", error: error.message
  end
end
