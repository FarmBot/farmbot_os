defmodule Farmbot.BotState.LocationData do
  @moduledoc false
  defstruct [
    scaled_encoders: nil,
    raw_encoders: nil,
    position: nil
  ]
end
