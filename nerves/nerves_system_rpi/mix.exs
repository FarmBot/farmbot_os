defmodule NervesSystemRpi.Mixfile do
  use Mix.Project

  @version Path.join([__DIR__, "..", "..", "VERSION"])
    |> File.read!
    |> String.strip

  def project do
    [app: :nerves_system_rpi,
     version: @version,
     elixir: "~> 1.3",
     compilers: Mix.compilers ++ [:nerves_package],
     description: description(),
     package: package(),
     deps: deps(),
     aliases: ["deps.precompile": ["nerves.env", "deps.precompile"]]]
  end

  def application do
    []
  end

  defp deps do
    [find_nerves(), find_nerves_toolchain(), find_nerves_system_br()]
  end

  defp find_nerves_toolchain() do
    {:nerves_toolchain_armv6_rpi_linux_gnueabi, "~> 0.9.0"}
  end

  defp find_nerves() do
    if File.exists?("../nerves") do
      {:nerves, path: "../nerves", override: true}
    else
      {:nerves, "0.5.1"}
    end
  end

  defp find_nerves_system_br do
    if File.exists?("../nerves_system_br") do
      {:nerves_system_br, path: "../nerves_system_br"}
    else
      {:nerves_system_br, "~> 0.9.2"}
    end
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
