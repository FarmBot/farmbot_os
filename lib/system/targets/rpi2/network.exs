defmodule Module.concat([Farmbot, System, "rpi2", Network]) do
  use Farmbot.System.NervesCommon.Network, target: "rpi2", modules: []
end
