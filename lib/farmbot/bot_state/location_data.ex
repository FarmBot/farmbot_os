defmodule Farmbot.BotState.LocationData do
  @moduledoc "Data about the bot's location in space"

  defmodule Vec3 do
    @moduledoc "3 Position Vector used for locations"
    defstruct [:x, :y, :z]

    @typedoc "x position."
    @type x :: number

    @typedoc "y position."
    @type y :: number

    @typedoc "z position."
    @type z :: number

    @typedoc "3 Position vector used for location data"
    @type t :: %__MODULE__{x: x , y: y , z: z }

    @doc "Builds a new 3 position vector."
    @spec new(x, y, z) :: t
    def new(x, y, z), do: %__MODULE__{x: x, y: y, z: z}
  end

  defstruct [
    position: Vec3.new(-1, -1, -1),
    scaled_encoders: Vec3.new(-1, -1, -1),
    raw_encoders: Vec3.new(-1, -1, -1)
  ]

  @typedoc "Data about the bot's position."
  @type t :: %__MODULE__{
    position: Vec3.t,
    scaled_encoders: Vec3.t,
    raw_encoders: Vec3.t
  }

  use Farmbot.BotState.Lib.Partition
end
