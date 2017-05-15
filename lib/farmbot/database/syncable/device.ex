defmodule Farmbot.Database.Syncable.Device do
  @moduledoc """
    A Device from the Farmbot API.
  """

  alias Farmbot.Database
  alias Database.Syncable
  use Syncable, model: [
    :name
  ], endpoint: {"/device", "/devices"}
end
