defmodule Farmbot.Log do
  @moduledoc "Farmbot Log Object."
  defstruct [
    :meta,
    :message,
    :created_at,
    :channels
  ]
end
