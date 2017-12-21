defmodule Farmbot.Farmware.Installer.Repository.ManifestType do
  @moduledoc false
  @behaviour Ecto.Type
  alias Farmbot.Farmware.Installer.Repository.Entry

  def type, do: :text

  # try to encode as json here.
  def cast(data) do
    Poison.encode(data)
  end

  def load(text) do
    Poison.decode(text, as: [struct(Entry)])
  end

  def dump(data), do: cast(data)
end
