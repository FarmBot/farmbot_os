defmodule Module.concat([Farmbot, System, "rpi", Network]) do
  use Farmbot.System.NervesCommon.Network, target: "rpi"
end
