require 'mutations'

module FBPi
  # Grabs a new auth token from the API.
  class FetchAuthToken < Mutations::Command
    required do
      duck :bot, methods: [:rest_client]
    end

    def execute
      binding.pry
    end
  end
end
