require 'securerandom'
require 'net/http'

module FBPi
  # Loads or creates a set of credentials for use on the MeshBlu IoT messaging
  # platform depending on wether or not the *.yml CREDENTIALS_FILE exists or not
  # If you ever need to reset your MeshBlu credentials, just delete
  # CREDENTIALS_FILE
  class Credentials
    CREDENTIALS_FILE = 'credentials.yml'
    attr_reader :credentials_file, :uuid, :token

    def initialize(file = CREDENTIALS_FILE)
      @credentials_file = file
      load_or_create
    end

    # Returns Hash containing the a :uuid and :token key. Triggers the creation
    # of new credentials if the current ones are found to be invalid.
    def load_or_create
      valid_credentials? ? load_credentials : create_credentials
      self
    end

    # Validates that the credentials file has a :uuid and :token key.
    # Returns Bool
    def valid_credentials?
      cred = load_credentials if File.file?(credentials_file)
      cred && cred.has_key?(:uuid) && cred.has_key?(:token)
    end

    # Uses the ruby securerandom library to make a new :uuid and :token. Also
    # registers with a new device :uuid and :token on skynet.im . Returns Hash
    # containing :uuid and :token key.
    def create_credentials
      post_url = URI("http://#{FBPi::Settings.meshblu_url}/devices")
      res  = Net::HTTP.post_form(post_url, {})
      json = JSON.parse(res.body).deep_symbolize_keys
      File.open(credentials_file, 'w+') { |file| file.write(json.to_yaml) }
      load_credentials
      json
    end

    ### Loads the credentials file from disk and returns it as a ruby hash.
    def load_credentials
      yml = YAML.load(File.read(credentials_file)) || {}
      @uuid, @token = yml[:uuid], yml[:token]
      yml
    end
  end
end
