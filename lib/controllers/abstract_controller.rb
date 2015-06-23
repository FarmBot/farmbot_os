module FBPi
  class AbstractController
    attr_reader :message, :bot, :mesh

    def initialize(message, bot, mesh)
      @message, @bot, @mesh = message, bot, mesh
    end

    def reply(type, payl = {})
      # http://json-rpc.org/wiki/specification#a1.2Response
      output = {id: message.id, error: nil, result: nil}
      payl   = payl.merge!(type: type)
      output[(type.to_s.downcase == "error") ? :error : :result] = payl
      mesh.emit message.from, output
    end
  end
end
