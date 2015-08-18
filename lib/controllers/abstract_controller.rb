require_relative '../command_objects/send_mesh_response'
# TODO: SimpleCov is not registering hits to this controller, despite the fact
# that tests exist. Investigate later. PRs welcome.
# :nocov:
module FBPi
  class AbstractController
    attr_reader :message, :bot, :mesh

    def initialize(message, bot, mesh)
      @message, @bot, @mesh = message, bot, mesh
    end

    def reply(method, reslt = {})
      SendMeshResponse.run!(original_message: message,
                            mesh:             mesh,
                            method:           method,
                            result:           reslt)
    end
  end
end
