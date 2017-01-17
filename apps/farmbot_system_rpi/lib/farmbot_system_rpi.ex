defmodule Module.concat([Farmbot, System, "rpi"]) do
  @moduledoc false
  @behaviour Farmbot.System

  use Farmbot.System.NervesCommon, target: "rpi"
end
