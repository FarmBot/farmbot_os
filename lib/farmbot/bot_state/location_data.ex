defmodule Farmbot.BotState.LocationData do
  @moduledoc "Data about the bot's location in space"
  
  defmodule Farmbot.BotState.Vec3 do
    @moduledoc "3 Position Vector used for locations"
    defstruct [:x, :y, :z]

    @typedoc "3 Position vector used for location data"
    @type t :: %__MODULE__{x: number, y: number, z: number}
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

  use GenServer
  require Logger

  @doc "Start the location server"
  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args) do
    {:ok, %__MODULE__{}}
  end
end
