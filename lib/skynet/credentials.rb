require 'securerandom'

module Credentials
  # Stores a references to the credentials yml file, which is used to persist
  # the user's skynet Token / ID across sessions. Returns String. parameterless
  def credentials_file
    'credentials.yml'
  end

  # Returns Hash containing the a :uuid and :token key. Triggers the creation of
  # new credentials if the current ones are found to be invalid.
  def credentials
    if valid_credentials?
      return load_credentials
    else
      return create_credentials
    end
  end

  # Validates that the credentials file has a :uuid and :token key. Returns Bool
  #
  def valid_credentials?
    if File.file?(credentials_file)
      cred = load_credentials
      return true if cred.has_key?(:uuid) && cred.has_key?(:token)
    end
    return false
  end

  # Uses the ruby securerandom library to make a new :uuid and :token. Also
  # registers with a new device :uuid and :token on skynet.im . Returns Hash
  # containing :uuid and :token key.
  def create_credentials
    hash = {
      uuid: (@uuid  = SecureRandom.uuid),
      token: (@token = SecureRandom.hex)
    }
    `curl -s -X POST -d 'uuid=#{@uuid}&token=#{@token}&type=farmbot' \
      http://skynet.im/devices`
    File.open(credentials_file, 'w+') {|file| file.write(hash.to_yaml) }
    return hash
  end

  ### Loads the credentials file from disk and returns it as a ruby hash.
  def load_credentials
    return YAML.load(File.read(credentials_file))
  end

end