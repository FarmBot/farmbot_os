defmodule Farmbot.Log.Meta do
  defstruct [:x, :y, :z]
end

defmodule Farmbot.Log do
  @moduledoc "Farmbot Log Object."
  alias Farmbot.Log.Meta
  
  defstruct [
    meta: %Meta{x: -1, y: -1, z: -1},
    message: nil,
    created_at: nil,
    channels: []
  ]
end
