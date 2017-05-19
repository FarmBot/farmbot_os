defmodule Farmbot.Database.Syncable.Sequence do
  @moduledoc """
    A Sequence from the Farmbot API.
  """

  alias Farmbot.Database
  alias Database.Syncable
  use Syncable, model: [], endpoint: {"/sequences", "/sequences"}
end
