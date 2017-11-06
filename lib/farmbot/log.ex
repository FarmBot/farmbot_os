defmodule Farmbot.Log.Meta do
  defstruct [:x, :y, :z, :type]
end

defmodule Farmbot.Log do
  @moduledoc "Farmbot Log Object."
  alias Farmbot.Log.Meta

  defstruct meta: %Meta{x: -1, y: -1, z: -1, type: :info},
            message: nil,
            created_at: nil,
            channels: []

  def new(message, created_at, channels, type) do
    meta = struct(Meta, [type: type])
    struct(__MODULE__, [message: message, created_at: created_at, channels: channels, meta: meta])
  end
end
