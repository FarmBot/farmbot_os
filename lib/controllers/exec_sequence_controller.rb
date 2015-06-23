require_relative 'abstract_controller'
require_relative '../command_objects/commands'

module FBPi
  class ExecSequenceController < AbstractController
    def call
      sequence.steps.each { |step| step.execute(bot) }
      reply "exec_sequence"
    rescue Mutations::ValidationException => error
      reply "error", error: error.message
    end

    def params
      @params ||= Hash(@message.params["command"])
    end

    def sequence
      @sequence ||= CreateSequence.run!(params)
    end
  end
end
