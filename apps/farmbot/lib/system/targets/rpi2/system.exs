defmodule Module.concat([Farmbot, System, "rpi2"]) do
  @moduledoc false
  @behaviour Farmbot.System

  use Farmbot.System.NervesCommon, target: "rpi2"
end
