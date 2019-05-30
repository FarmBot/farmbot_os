defmodule FarmbotFirmware.VCR do
  @moduledoc """
  Helpers for working with Firmware tapes
  """
  alias FarmbotFirmware.GCODE

  @doc "Convert a .txt file to Elixir terms"
  def to_elixir!(path) do
    File.stream!(path)
    |> Stream.map(&split_decode/1)
    |> Enum.to_list()
  end

  @doc "Play a tape back on a server"
  def playback!(path, firmware_server \\ FarmbotFirmware) do
    path
    |> to_elixir!()
    |> Enum.reject(fn
      {:in, _timestamp, _type, _code} -> true
      {:out, _timestamp, _type, _code} -> false
    end)
    |> Enum.each(fn {:out, _timestamp, type, code} ->
      apply(FarmbotFirmware, type, [firmware_server, code])
    end)
  end

  defp split_decode(data) do
    data
    |> do_split()
    |> do_decode()
  end

  defp do_split(data) do
    data
    |> String.trim()
    |> String.split(" ")
  end

  defp do_decode([direction, timestamp | rest]) do
    direction = decode_direction(direction)
    timestamp = decode_timestamp(timestamp)

    case GCODE.decode(Enum.join(rest, " ")) do
      {_, {kind, _args}} = code
      when kind not in [
             :parameter_read,
             :status_read,
             :pin_read,
             :end_stops_read,
             :position_read,
             :software_version_read
           ] ->
        {direction, timestamp, :command, code}

      code ->
        {direction, timestamp, :request, code}
    end
  end

  defp decode_direction("<"), do: :in
  defp decode_direction(">"), do: :out
  defp decode_timestamp(timestamp), do: String.to_integer(timestamp)
end
