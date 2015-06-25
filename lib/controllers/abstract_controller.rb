require_relative '../command_objects/send_mesh_response'

module FBPi
  class AbstractController
    attr_reader :message, :bot, :mesh

    def initialize(message, bot, mesh)
      @message, @bot, @mesh = message, bot, mesh
    end

    def reply(method, reslt = {})
      SendMeshResponse.run!(message: message,
                            mesh:    mesh,
                            method:  method,
                            result:  reslt)
    end
  end
end
