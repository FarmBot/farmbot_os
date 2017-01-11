defmodule NervesSystemRpi.Mixfile do
  use Mix.Project

  @version Path.join(__DIR__, "VERSION")
    |> File.read!
    |> String.strip

  def project do
    [app: :nerves_system_rpi,
     version: @version,
     elixir: "~> 1.3",
     archives: [nerves_bootstrap: "~> 0.2.1"],
     aliases: ["deps.precompile": ["nerves.env", "deps.precompile"]],
     compilers: Mix.compilers ++ [:nerves_package],
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    []
  end

  defp deps do
    [{:nerves, "~> 0.4.0"},
     {:nerves_system_br, "~> 0.8.1"},
     {:nerves_toolchain_armv6_rpi_linux_gnueabi, "~> 0.8.0"}]
  end

  defp description do
    """
    Nerves System - Raspberry Pi A+ / B+ / B / Zero
    """
  end

  defp package do
    [maintainers: ["Frank Hunleth", "Justin Schneck"],
    files: ["LICENSE", "mix.exs", "nerves_defconfig", "nerves.exs", "README.md", "VERSION", "rootfs-additions", "fwup.conf", "cmdline.txt", "linux-4.4.defconfig", "config.txt", "post-createfs.sh"],
     licenses: ["Apache 2.0"],
     links: %{"Github" => "https://github.com/nerves-project/nerves_system_rpi"}]
  end
end
