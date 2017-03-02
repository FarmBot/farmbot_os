defmodule Module.concat([Farmbot, System, "rpi", Updates]) do
  use Farmbot.System.NervesCommon.Updates, target: "rpi"
end
