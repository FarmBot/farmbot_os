require 'securerandom'

class Credentials
  CREDENTIALS_FILE = 'credentials.yml'
  attr_reader :credentials_file, :uuid, :token

  def initialize(file = CREDENTIALS_FILE)
    @credentials_file = file
    load_or_create
  end

  # Returns Hash containing the a :uuid and :token key. Triggers the creation of
  # new credentials if the current ones are found to be invalid.
  def load_or_create
    valid_credentials? ? load_credentials : create_credentials
  end

  # Validates that the credentials file has a :uuid and :token key. Returns Bool
  #
  def valid_credentials?
    cred = load_credentials if File.file?(credentials_file)
    cred && cred.has_key?(:uuid) && cred.has_key?(:token)
  end

  # Uses the ruby securerandom library to make a new :uuid and :token. Also
  # registers with a new device :uuid and :token on skynet.im . Returns Hash
  # containing :uuid and :token key.
  def create_credentials
    # TODO: Use a real HTTP library with error handling.
    hash = { uuid: (@uuid  = SecureRandom.uuid),
             token: (@token = SecureRandom.hex) }
    `curl -s -X POST -d 'uuid=#{@uuid}&token=#{@token}&type=farmbot' \
      http://skynet.im/devices`
    File.open(credentials_file, 'w+') {|file| file.write(hash.to_yaml) }
    return hash
  end

  ### Loads the credentials file from disk and returns it as a ruby hash.
  def load_credentials
    yml = YAML.load(File.read(credentials_file))
    @uuid, @token = yml[:uuid], yml[:token]
    yml
  end

end
