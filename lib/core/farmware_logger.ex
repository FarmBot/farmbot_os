defmodule FarmbotOS.FarmwareLogger do
  require Logger

  defstruct name: "UNKNOWN FARMWARE?"
  def new(name), do: %__MODULE__{name: name}

  defimpl Collectable do
    alias FarmbotOS.FarmwareLogger, as: S

    def into(%S{} = logger), do: {logger, &collector/2}
    defp collector(%S{} = logger, :done), do: logger
    defp collector(%S{} = _, :halt), do: :ok

    defp collector(%S{} = logger, {:cont, text}) do
      Logger.debug("[#{inspect(logger.name)}] " <> text)
      logger
    end
  end
end
