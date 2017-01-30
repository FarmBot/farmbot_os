defmodule NervesSystemRpi2.Mixfile do
  use Mix.Project

  @version Path.join(__DIR__, "VERSION")
    |> File.read!
    |> String.strip

  def project do
    [app: :nerves_system_rpi2,
     version: @version,
     elixir: "~> 1.2",
     compilers: Mix.compilers ++ [:nerves_package],
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    []
  end

  defp deps do
    [{:nerves,  "~> 0.4.0"},
     {:nerves_toolchain_arm_unknown_linux_gnueabihf, "~> 0.8.0"}]
    ++ [find_nerves_system_br()]
  end

  def find_nerves_system_br do
    if File.exists?("../nerves_system_br") do
      {:nerves_system_br, in_umbrella: true}
    else
      {:nerves_system_br, "~> 0.8.1"}
    end
  end

  defp description do
    """
    Nerves System - Raspberry Pi 2 B
    """
  end

  defp package do
    [maintainers: ["Frank Hunleth", "Justin Schneck"],
    files: ["LICENSE", "mix.exs", "nerves_defconfig", "nerves.exs", "README.md", "VERSION", "rootfs-additions", "fwup.conf", "cmdline.txt", "linux-4.4.defconfig", "config.txt", "post-createfs.sh"],
     licenses: ["Apache 2.0"],
     links: %{"Github" => "https://github.com/nerves-project/nerves_system_rpi2"}]
  end
end
