use Mix.Config
config :farmbot, state_path: "/tmp"
# when booting on qemu, we only have one interface, and we expect it to be
# automatically configured.
config :network,
  hostapd: false,
  auto_dhcp: "eth0",
  interfaces: [
    {"eth0", :ethernet},
  ]
