require_relative 'abstract_controller'
require_relative '../command_objects/commands'

module FBPi
  class ExecSequenceController < AbstractController
    def call
      sequence.exec(bot)
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
