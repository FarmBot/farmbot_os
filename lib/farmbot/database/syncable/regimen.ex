defmodule Farmbot.Database.Syncable.Regimen do
  @moduledoc """
    A Regimen from the Farmbot API.
  """

  alias Farmbot.Database
  alias Database.Syncable
  use Syncable, model: [
    :name,
    :regimen_items
  ], endpoint: {"/regimens", "/regimens"}
end
