require_relative 'abstract_controller'
require_relative '../sequences/sequences'

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
    @sequence ||= SequenceFactory.run!(payload)
  end
end
