defmodule Module.concat([Farmbot, System, "rpi3"]) do
  @moduledoc false
  @behaviour Farmbot.System

  use Farmbot.System.NervesCommon, target: "rpi3"
end
