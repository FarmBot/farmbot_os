defmodule NervesSystemRpi.Mixfile do
  use Mix.Project

  @version Path.join([__DIR__, "..", "..", "VERSION"])
    |> File.read!
    |> String.strip

  def project do
    [app: :nerves_system_rpi0w,
     version: @version,
     elixir: "~> 1.3",
     compilers: Mix.compilers ++ [:nerves_package],
     deps: deps(),
     aliases: ["deps.precompile": ["nerves.env", "deps.precompile"]]]
  end

  def application do
    []
  end

  defp deps do
    [{:nerves, "~> 0.5.1", runtime: false },
     {:nerves_system_br, github: "tmecklem/nerves_system_br", branch: "master", runtime: false},
     {:nerves_toolchain_armv6_rpi_linux_gnueabi, "~> 0.10.0", runtime: false}]
  end
end
