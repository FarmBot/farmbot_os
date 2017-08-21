defmodule ExSyslogger.FarmbotFormatter do
  @moduledoc false

  @doc false
  defdelegate compile(str), to: Logger.Formatter

  @doc false
  def format(format, level, unformatted_msg, timestamp, meta, cfg_meta) do
    msg = try_string(unformatted_msg)
    format |> Logger.Formatter.format(level, msg, timestamp, Keyword.take(meta, cfg_meta)) |> to_string()
  end

  defp try_string(log) do
    try do
      to_string(log)
    rescue
      _ -> inspect(log)
    end
  end
end
