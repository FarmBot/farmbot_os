defmodule Serialized do
  @moduledoc """
    Farmbots Hardware State tracker State module. This is tied into
    the frontend so don't change it unless you know what you are doing.
  """
  defstruct [
    # Hardware
    mcu_params: %{},
    location: [0,0,0],
    pins: %{},

    # configuration
    locks: [],
    configuration: %{},
    informational_settings: %{},

    authorization: %{}, # DELETEME

    # farm scheduler
    farm_scheduler: %Farmbot.Scheduler.State.Serializer{}
  ]
  @type t :: %__MODULE__{
    locks: list(%{reason: String.t}),
    mcu_params: map,
    location: [number, ...], # i should change this to a tuple
    pins: %{},
    configuration: %{},
    informational_settings: %{},
    farm_scheduler: Farmbot.Scheduler.State.Serializer.t,
  }
end
