defmodule Farmbot.BotState.Job do
  @moduledoc "Job that can be represented as a progress bar of some sort."

  defmodule PercentProgress do
    @moduledoc "Progress represented 0-100"
    defstruct [
      status: :working,
      unit: :percent,
      percent: 0
    ]
    
    @typedoc "A Progress struct represented as a percentage"
    @type t :: %__MODULE__{
      status: Farmbot.BotState.Job.status,
      unit: :percent,
      percent: number
    }
  end

  defmodule ByteProgress do
    @moduledoc "Progress represented as a number of bytes."

    defstruct [
      status: :working,
      unit: :bytes,
      bytes: 0
    ]
    
    @typedoc "A Progress struct represented by number of bytes."
    @type t :: %__MODULE__{
      status: Farmbot.BotState.Job.status,
      unit: :bytes,
      bytes: number
    }
  end
  
  @typedoc "Job struct"
  @type t :: PercentProgress.t | ByteProgress.t 
  
  @typedoc "Status of the job"
  @type status :: :working | :complete | :error
end
