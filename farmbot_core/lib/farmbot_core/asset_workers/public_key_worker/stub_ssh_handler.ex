defmodule FarmbotCore.PublicKeyHandler.StubSSHHandler do
  @behaviour FarmbotCore.Asset.PublicKey
  def ready?(), do: true
  def add_key(_key), do: :ok
end