defmodule Farmbot.Farmware.Runtime.HTTPServer.JWT do
  @moduledoc "Farmware JWT"

  defstruct [:start_time]

  @typedoc "Farmware JWT."
  @type t :: %__MODULE__{
    start_time: binary,
  }
end
