defmodule FarmbotCore.BotState.JobProgress do
  @moduledoc "Interface for job progress."

  @typedoc "Unit of the job. Will be `percent` | `bytes`"
  @type unit :: String.t()


  @typedoc "Status of the job. Will be `error` | `working` | `complete`"
  @type status :: String.t()

  alias FarmbotCore.BotState.JobProgress

  defmodule Percent do
    @moduledoc "Percent job."
    defstruct status: "working", percent: 0, unit: "percent", type: "ota", time: nil, file_type: nil

    defimpl Inspect, for: __MODULE__ do
      def inspect(%{percent: percent}, _) do
        "#Percent<#{percent}>"
      end
    end

    @type t :: %__MODULE__{
            status: JobProgress.status(),
            percent: integer,
            unit: JobProgress.unit(),
            type: String.t,
            file_type: binary(),
            time: DateTime.t()
          }
  end

  defmodule Bytes do
    @moduledoc "Bytes job."
    defstruct status: "working", bytes: 0, unit: "bytes", type: "ota", time: nil, file_type: nil

    defimpl Inspect, for: __MODULE__ do
      def inspect(%{bytes: bytes}, _) do
        "#bytes<#{bytes}>"
      end
    end

    @type t :: %__MODULE__{
            status: JobProgress.status(),
            bytes: integer,
            unit: JobProgress.unit(),
            type: String.t(),
            file_type: binary(),
            time: DateTime.t()
          }
  end

  @type t :: Bytes.t() | Percent.t()
end
