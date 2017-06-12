defmodule Farmbot.CeleryScript.Error do
  defexception [
    {:context, nil},
    :message
  ]
end
