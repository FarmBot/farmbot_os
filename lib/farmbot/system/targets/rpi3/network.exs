defmodule Module.concat([Farmbot, System, "rpi3", Network]) do
  use Farmbot.System.NervesCommon.Network,
    target: "rpi3", modules: ["brcmfmac"], callback: fn() ->
      # iw dev wlan0 interface add wlan1 type __ap
      # iw_args = ~w"dev wlan0 interface add wlan1 type __ap"
      # {_, 0} = System.cmd("iw", iw_args)
      :ok
    end
end
