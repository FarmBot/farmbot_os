defmodule Farmbot.Database.Syncable.Peripheral do
  @moduledoc """
    A Peripheral from the Farmbot API.
  """

  alias Farmbot.Database
  alias Database.Syncable
  use Syncable, model: [], endpoint: {"/peripherals", "/peripherals"}
end
