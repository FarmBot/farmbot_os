defmodule Farmbot.Database.Syncable.Tool do
  @moduledoc """
    A Tool from the Farmbot API.
  """

  alias Farmbot.Database
  alias Database.Syncable
  use Syncable, model: [], endpoint: {"/tool", "/tools"}
end
