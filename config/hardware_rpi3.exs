use Mix.Config
config :farmbot, state_path: "/state"
# on rpi3 we have wifi (with host mode) and ethernet available.
# on boot we should bring up hostapd to allow for configurations.
config :network,
  hostapd: "wlan0",
  auto_dhcp: false,
  interfaces: [
    {"eth0", :ethernet},
    {"wlan0", :wifi}
  ]
