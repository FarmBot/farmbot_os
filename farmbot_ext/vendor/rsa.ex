defmodule RSA do
  # Decrypt using the private key
  def decrypt(cyphertext, {:private, key}) do
    cyphertext |> :public_key.decrypt_private(key)
  end

  # Decrypt using the public key
  def decrypt(cyphertext, {:public, key}) do
    cyphertext |> :public_key.decrypt_public(key)
  end

  # Encrypt using the private key
  def encrypt(text, {:private, key}) do
    text |> :public_key.encrypt_private(key)
  end

  # Encrypt using the public key
  def encrypt(text, {:public, key}) do
    text |> :public_key.encrypt_public(key)
  end

  # Decode a key from its text representation to a PEM structure
  def decode_key(text) do
    [entry] = text |> :public_key.pem_decode()
    entry |> :public_key.pem_entry_decode()
  end
end
