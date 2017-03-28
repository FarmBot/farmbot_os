use Mix.Config

version = Path.join([__DIR__, "..", "..", "VERSION"])
|> File.read!
|> String.strip

pkg = :nerves_system_rpi0w
nerves_target = "rpi0w"

config pkg, :nerves_env,
  type: :system,
  version: version,
  compiler: :nerves_package,
  artifact_url: [
    "https://github.com/FarmBot/farmbot_os/releases/download/v#{version}/farmbot.rootfs-#{nerves_target}-#{version}.tar.gz"
    ],
  platform: Nerves.System.BR,
  platform_config: [
    defconfig: "nerves_defconfig",
  ],
  checksum: [
    "nerves_defconfig",
    "rootfs-additions",
    "linux-4.4.defconfig",
    "fwup.conf",
    "cmdline.txt",
    "config.txt",
    "post-createfs.sh"
  ]
