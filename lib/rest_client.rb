# Wraps around the Farmbot REST client gem to provide RPi specific functions.
require 'farmbot-resource'

module FBPi
  class RPiRestClient < FbResource::Client
    def initialize(token)
      super() { |c| config.token = token }
    end
  end
end
