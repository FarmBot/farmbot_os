defmodule RSA do
  # Encrypt using the public key
  def encrypt(text, {:public, key}) do
    text |> :public_key.encrypt_public(key)
  end

  # Decode a key from its text representation to a PEM structure
  def decode_key(text) do
    [entry] = :public_key.pem_decode(text)
    :public_key.pem_entry_decode(entry)
  end
end
