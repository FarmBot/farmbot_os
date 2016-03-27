# a "Write only" file dump for sharing secrets. The web server has the private
# key and is the only party able to read the file.
require 'securerandom'
require 'base64'

class SecretFile
  attr_reader :public_key, :file_path, :cipher_text

  def initialize(public_key, file_path)
    @public_key, @file_path = public_key, file_path
  end

  def self.save_password(public_key, email, password)
    self
      .new(public_key, "db/secrets.txt")
      .write({email:    email,
              password: password})
  end

  def write(payload_obj)
    # Add a UUID for comparison / debugging purposes
    text = payload_obj.merge!(id: SecureRandom.uuid, version: 1).to_json
    self.cipher_text = text
    cipher_text
  end

  def cipher_text=(text)
    text = Base64.encode64(public_key.public_encrypt(text))
    File.open(file_path, 'w') { |f| f.write(text) }
    @cipher_text = text
  end

  def cipher_text
    if @cipher_text || File.file?(file_path)
      return @cipher_text ||= File.read(file_path)
    else
      raise "Attempted to access bot credentials, but none were found. " \
            "Did you run `ruby setup.rb`?"
    end
  end
end
