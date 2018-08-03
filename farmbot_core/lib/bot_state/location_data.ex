defmodule Farmbot.BotState.LocationData do
  @moduledoc false
  defstruct [
    scaled_encoders: %{x: -1, y: -1, z: -1},
    raw_encoders: %{x: -1, y: -1, z: -1},
    position: %{x: -1, y: -1, z: -1}
  ]
end
