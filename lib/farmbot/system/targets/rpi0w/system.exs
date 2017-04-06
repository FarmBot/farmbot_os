defmodule Module.concat([Farmbot, System, "rpi0w"]) do
  @moduledoc false
  @behaviour Farmbot.System

  use Farmbot.System.NervesCommon, target: "rpi0w"
end
