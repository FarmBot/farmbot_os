defmodule Module.concat([Farmbot, System, "rpi3", Network]) do
  use Farmbot.System.NervesCommon.Network, target: "rpi3"
end
