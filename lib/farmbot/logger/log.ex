defmodule Farmbot.Log do
  @moduledoc "Farmbot Log Object."

  @version Farmbot.Project.version() |> Version.parse!
  defstruct [
    time: nil,
    level: nil,
    verbosity: nil,
    message: nil,
    meta: nil,
    function: nil,
    file: nil,
    line: nil,
    module: nil,
    version: @version
  ]

  defimpl String.Chars, for: Farmbot.Log do
    def to_string(log) do
      if log.meta[:color] && function_exported?(IO.ANSI, log.meta[:color], 0) do
        "#{apply(IO.ANSI, log.meta[:color], [])}#{log.message}#{color(:normal)}\n"
      else
        "#{color(log.level)}#{log.message}#{color(:normal)}\n"
      end
    end

    defp color(:debug),   do: IO.ANSI.light_blue()
    defp color(:info),    do: IO.ANSI.cyan()
    defp color(:busy),    do: IO.ANSI.blue()
    defp color(:success), do: IO.ANSI.green()
    defp color(:warn),    do: IO.ANSI.yellow()
    defp color(:error),   do: IO.ANSI.red()
    defp color(:normal),  do: IO.ANSI.normal()
    defp color(_),        do: IO.ANSI.normal()
  end

end
