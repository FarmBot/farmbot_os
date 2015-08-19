require_relative '../command_objects/send_mesh_response'
# TODO: SimpleCov is not registering hits to this controller, despite the fact
# that tests exist. Investigate later. PRs welcome.
# :nocov:
module FBPi
  # The base controller from which all other controllers inherit. Takes in the
  # current bot instance, an FBPi::MeshMessage and the current MeshBlu
  # connection and routes the JSONRPC request to wherever it needs to go in the
  # app.
  class AbstractController
    attr_reader :message, :bot, :mesh

    def initialize(message, bot, mesh)
      @message, @bot, @mesh = message, bot, mesh
    end

    def call
      raise "A child of AbstractController is expected to implement #call()"
    end

    def reply(method, reslt = {})
      SendMeshResponse.run!(original_message: message,
                            mesh:             mesh,
                            method:           method,
                            result:           reslt)
    end
  end
end
