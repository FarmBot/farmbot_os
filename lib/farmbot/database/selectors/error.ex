defmodule Farmbot.Database.Selectors.Error do
  @moduledoc "Error message for selectors."
  defexception [
    :syncable_id,
    :syncable,
    :message,
  ]
end
