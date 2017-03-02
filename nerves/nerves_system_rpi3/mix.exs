defmodule NervesSystemRpi3.Mixfile do
  use Mix.Project

  @version Path.join([__DIR__, "..", "farmbot", "VERSION"])
    |> File.read!
    |> String.strip

  def project do
    [app: :nerves_system_rpi3,
     version: @version,
     elixir: "~> 1.2",
     compilers: Mix.compilers ++ [:nerves_package],
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application, do: []

  defp deps do
    [find_nerves(), find_nerves_toolchain(), find_nerves_system_br()]
  end

  defp find_nerves_toolchain() do
    {:nerves_toolchain_arm_unknown_linux_gnueabihf, "~> 0.9.0"}
  end

  defp find_nerves() do
    if File.exists?("../nerves") do
      {:nerves, path: "../nerves"}
    else
      # {:nerves, github: "nerves-project/nerves", tag: "4d1f9bee92b65fc6fbd4f1c1685e46a55baebee1", override: true}
      {:nerves,  "~> 0.4.8"}
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
   Nerves System - Raspberry Pi 3 B
   """
  end

  defp package do
   [maintainers: ["Frank Hunleth", "Justin Schneck"],
    files: ["LICENSE", "mix.exs", "nerves_defconfig", "nerves.exs", "README.md", "VERSION", "rootfs-additions", "fwup.conf", "cmdline.txt", "linux-4.4.defconfig", "config.txt", "post-createfs.sh"],
    licenses: ["Apache 2.0"],
    links: %{"Github" => "https://github.com/nerves-project/nerves_system_rpi3"}]
  end
end
