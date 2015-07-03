require_relative 'abstract_controller'
require_relative '../command_objects/commands'

module FBPi
  class ExecSequenceController < AbstractController
    def call
      sequence
        .steps
        .sort{ |a, b| a.position <=> b.position}
        .each { |step| step.execute(bot) }
      reply "exec_sequence", params
    rescue Mutations::ValidationException => error
      reply "error", error: error.message
    end

    def params
      @params ||= (@message.params || {})
    end

    def sequence
      @sequence ||= CreateSequence.run!(params)
    end
  end
end
