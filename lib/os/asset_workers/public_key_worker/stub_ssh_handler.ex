defmodule FarmbotOS.PublicKeyHandler.StubSSHHandler do
  @behaviour FarmbotOS.Asset.PublicKey
  def ready?(), do: true
  def add_key(_key), do: :ok
end
