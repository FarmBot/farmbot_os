defmodule Farmbot.BotState.JobProgress do
  @moduledoc "Interface for job progress"
  defstruct [:status, :progress]

  @typedoc "Status of a job."
  @type status :: any

  @typedoc "Object for 0 - 100 information."
  @type t :: %__MODULE__{status: status, progress: integer}
end
