defmodule Farmbot.Database.Syncable.Device do
  @moduledoc """
    A Device from the Farmbot API.
  """

  alias Farmbot.{Context, Database}
  alias Database.Syncable
  use Syncable, model: [
    :name,
    :timezone
  ], endpoint: {"/device", "/device"}

  def on_fetch(%Context{} = context, %__MODULE__{timezone: _tz}) do
    tz = "America/Los_Angeles"
    true = Farmbot.BotState.update_config(context, "timezone", tz)
  end
end
