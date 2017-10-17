defmodule Farmbot.Target.Protocols do
  @moduledoc false

  require Logger

  def start_link(_, _) do
    Logger.info("Loading consolidated protocols.")

    for beamfile <- Path.wildcard("/srv/erlang/lib/farmbot-*/consolidated/*.beam") do
      beamfile
      |> String.replace_suffix(".beam", "")
      |> to_charlist()
      |> :code.load_abs()
    end
    :ignore
  end
end
