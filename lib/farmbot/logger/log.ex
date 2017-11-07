defmodule Farmbot.Log do
  @moduledoc "Farmbot Log Object."

  defstruct [:time, :level, :verbosity, :message,
             :meta, :function, :file, :line, :module]

  defimpl Inspect, for: __MODULE__ do
    def inspect(log, _) do
      color = if log.meta[:color] do
        Farmbot.DebugLog.color(log.meta[:color])
      else
        color(log.level)
      end
      "#{color}#{log.message}#{Farmbot.DebugLog.color(:NC)}\n"
    end

    defp color(:debug),   do: Farmbot.DebugLog.color(:LIGHT_BLUE)
    defp color(:info),    do: Farmbot.DebugLog.color(:CYAN)
    defp color(:busy),    do: Farmbot.DebugLog.color(:BLUE)
    defp color(:success), do: Farmbot.DebugLog.color(:GREEN)
    defp color(:warn),    do: Farmbot.DebugLog.color(:YELLOW)
    defp color(:error),   do: Farmbot.DebugLog.color(:RED)
    defp color(_),        do: Farmbot.DebugLog.color(:NC)
  end

end
