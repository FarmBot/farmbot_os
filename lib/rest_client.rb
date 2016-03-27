# Wraps around the Farmbot REST client gem to provide RPi specific functions.
require 'farmbot-resource'
require_relative 'secret_file'

module FBPi
  class RPiRestClient < FbResource::Client
    CREDENTIALS_FILE = 'db/secrets.txt'
    TRANSLATIONS = {
      "sub"=> "email",
      "iat"=> "token_issued_at",
      "jti"=> "token_id",
      "iss"=> "webapp_url",
      "exp"=> "token_expiration",
      "mqtt"=>"mqtt_url",
      "bot"=> "device_uuid"
    }
    def initialize(url)
      public_key  = FBPi::RPiRestClient.public_key(url)
      credentials = SecretFile.new(public_key, CREDENTIALS_FILE).cipher_text
      token = FbResource::Client.get_token(credentials: credentials, url: url)
      unpack_token_settings(token)
      super() { |c| config.token = token }
    end

    # To prevent adding a bunch of setup steps, we pull most config out of the
    # API token. That way users don't need to worry about pointing to the right
    # servers or updating settings.
    def unpack_token_settings(token)
      settings = JSON.parse(Base64.decode64(token.split(".")[1]))
      TRANSLATIONS.each do |key, val|
        FBPi::Settings[val] = settings[key] || "#{key} not set."
      end
      FBPi::Settings.save
    end
  end
end
