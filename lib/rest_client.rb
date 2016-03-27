# Wraps around the Farmbot REST client gem to provide RPi specific functions.
require 'farmbot-resource'
require_relative 'secret_file'

module FBPi
  class RPiRestClient < FbResource::Client
    CREDENTIALS_FILE = 'db/secrets.txt'
    ERROR_MESSAGE    = "Credentials missing. Please run `ruby setup.rb` first."

    def initialize(url)
      public_key  = FBPi::RPiRestClient.public_key(url)
      credentials = SecretFile.new(public_key, CREDENTIALS_FILE).cipher_text
      token = FbResource::Client.get_token(credentials: credentials, url: url)
      super() { |c| config.token = token }
    end
  end
end
