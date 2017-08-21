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
    raw_encoders: Vec3.new(-1, -1, -1),
    end_stops: "-1-1-1-1-1-1"
  ]

  @typedoc "Data about the bot's position."
  @type t :: %__MODULE__{
    position: Vec3.t,
    scaled_encoders: Vec3.t,
    raw_encoders: Vec3.t,
    end_stops: binary
  }

  use Farmbot.BotState.Lib.Partition

  def report_current_position(part, x, y, z) do
    GenServer.call(part, {:report_current_position, Vec3.new(x,y,z)})
  end

  def report_encoder_position_scaled(part, x, y, z) do
    GenServer.call(part, {:report_encoder_position_scaled, Vec3.new(x,y,z)})
  end

  def report_encoder_position_raw(part, x, y, z) do
    GenServer.call(part, {:report_encoder_position_raw, Vec3.new(x,y,z)})
  end

  def report_end_stops(part, xa, xb, ya, yb, za, zb) do
    GenServer.call(part, {:report_end_stops, "#{xa}#{xb}#{ya}#{yb}#{za}#{zb}"})
  end

  def partition_call({:report_current_position, pos}, _, state) do
    {:reply, :ok, %{state | position: pos}}
  end

  def partition_call({:report_encoder_position_scaled, pos}, _, state) do
    {:reply, :ok, %{state | scaled_encoders: pos}}
  end

  def partition_call({:report_encoder_position_raw, pos}, _, state) do
    {:reply, :ok, %{state | raw_encoders: pos}}
  end

  def partition_call({:report_end_stops, stops}, _, state) do
    {:reply, :ok, %{state | end_stops: stops}}
  end
end
