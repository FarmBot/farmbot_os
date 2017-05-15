defmodule Farmbot.Database.Syncable.Regimen do
  @moduledoc """
    A Regimen from the Farmbot API.
  """

  alias Farmbot.Database
  alias Database.Syncable
  use Syncable, model: [
    :regimen_items
  ], endpoint: {"/regimen", "/regimens"}
end
