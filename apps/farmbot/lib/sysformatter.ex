defmodule Farmbot.SysFormatter do
  @moduledoc """
    Formats sysmessages
  """

  @doc """
  Compiles a format string into an array that the `format/6` can handle.
  It uses Logger.Formatter.
  """
  @spec compile({atom, atom}) :: {atom, atom}
  @spec compile(binary | nil) :: [Logger.Formatter.pattern | binary]

  defdelegate compile(str), to: Logger.Formatter

  @doc """
    Formats a string
  """
  @spec format({atom, atom} | [Logger.Formatter.pattern | binary],
               Logger.level, Logger.message, Logger.Formatter.time,
               Keyword.t, list(atom)) :: IO.chardata

  def format(format, level, msg, timestamp, metadata, config_metadata) do
    metadata = metadata |> Keyword.take(config_metadata)

    msg_str = format
      |> Logger.Formatter.format(level, msg, timestamp, metadata)
      |> try_string()
  end

  defp try_string(stuff) do
    try do
      to_string(stuff)
    rescue
      _ -> inspect(stuff)
    end
  end
end
