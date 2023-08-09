defmodule FarmbotOS.BotState.JobProgress do
  @moduledoc "Interface for job progress."

  @typedoc "Unit of the job. Will be `percent` | `bytes`"
  @type unit :: String.t()

  @typedoc "Status of the job. Will be `error` | `working` | `complete`"
  @type status :: String.t()

  alias FarmbotOS.BotState.JobProgress

  defmodule Percent do
    @moduledoc "Percent job."
    defstruct status: "Working",
              percent: 0,
              unit: "percent",
              type: "",
              time: nil,
              file_type: nil

    defimpl Inspect, for: __MODULE__ do
      def inspect(%{percent: percent}, _) do
        "#Percent<#{percent}>"
      end
    end

    @type t :: %__MODULE__{
            status: JobProgress.status(),
            percent: integer,
            unit: JobProgress.unit(),
            type: String.t(),
            file_type: binary(),
            time: DateTime.t()
          }
  end
end
