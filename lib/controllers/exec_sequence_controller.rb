require_relative 'abstract_controller'
require_relative '../command_objects/commands'

class ExecSequenceController < AbstractController
  def call
    sequence.steps.each do |step|
      step.execute(bot)
    end
    reply "exec_sequence"
  rescue Mutations::ValidationException => error
    reply "error", error: error.message
  end

  def payload
    @payload ||= Hash(@message.payload["command"])
  end

  def sequence
    @sequence ||= CreateSequence.run!(payload)
  end
end
