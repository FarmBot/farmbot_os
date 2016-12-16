defmodule Farmbot.Mixfile do
  use Mix.Project

  def target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
  def target(_), do: System.get_env("NERVES_TARGET") || "development"

  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip
  @compat_version Path.join(__DIR__, "COMPAT") |> File.read! |> String.strip |> String.to_integer

  def project do
    [app: :farmbot,
     test_coverage: [tool: ExCoveralls],
     version: @version,
     target: target(Mix.env),
     archives: [nerves_bootstrap: "~> 0.2.0"],
     deps_path: "deps/#{target(Mix.env)}",
     build_path: "_build/#{target(Mix.env)}",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     config_path: "config/config.exs",
     aliases: aliases(Mix.env),
     deps: deps(Mix.env) ]
  end

  def application do
    [mod: {Farmbot, [%{target: target(Mix.env), compat_version: @compat_version,
                       version: @version, env: Mix.env}]},
     applications: apps(Mix.env),
     included_applications: [:gen_mqtt]]
  end

  # common for test, prod, and dev
  def apps do
    [:logger,
     :nerves_uart,
     :nerves_interim_wifi,
     :httpotion,
     :poison,
     :gen_stage,
     :nerves_lib,
     :rsa,
     :runtime_tools,
     :mustache,
     :timex,
     :farmbot_auth,
     :farmbot_configurator,
     :vmq_commons,
     :amnesia,
     :quantum]
  end

  # on device
  def apps(:prod) do
    apps ++ platform_apps(target(:prod)) ++ [:nerves, :nerves_firmware_http]
  end

  # dev
  def apps(:dev), do: apps ++ [:fake_nerves]

  # test
  def apps(:test) do
    apps ++ [
      :plug,
      :cors_plug,
      :cowboy,
      :faker
    ]
  end

  def deps do
    [
      {:nerves_uart, "~> 0.1.0"},
      {:nerves_interim_wifi, "~> 0.1.0"},
      {:httpotion, "~> 3.0.0"},
      {:poison, "~> 3.0", override: true},
      {:gen_stage, "~> 0.4"},
      {:nerves_lib, github: "nerves-project/nerves_lib"},
      {:gen_mqtt, "~> 0.3.1"},
      {:vmq_commons, "1.0.0", manager: :rebar3}, # This is for mqtt to work.
      {:mustache, "~> 0.0.2"},
      {:timex, "~> 3.0"},
      {:socket, github: "meh/elixir-socket"},
      {:amnesia, github: "meh/amnesia"},
      {:quantum, ">= 1.8.1"},
      # {:farmbot_auth, github: "Farmbot/farmbot_auth"},
      {:farmbot_auth, path: "../farmbot_auth"},
      # {:farmbot_configurator, github: "Farmbot/farmbot_configurator"}
      {:farmbot_configurator, path: "../farmbot_configurator"}
    ]
  end

  def deps(:prod) do
    deps ++ platform_deps(target(Mix.env)) ++ system(target(Mix.env)) ++
    [
     {:nerves, github: "nerves-project/nerves", override: true},
     {:nerves_firmware_http, github: "nerves-project/nerves_firmware_http"}
    ]
  end

  def deps(:test) do
    deps ++ deps(:dev) ++
    [ {:plug, "~> 1.0"},
      {:cors_plug, "~> 1.1"},
      {:cowboy, "~> 1.0.0"},
      {:excoveralls, "~> 0.5"},
      {:faker, "~> 0.7"} ]
  end

  def deps(:dev) do
    deps ++ [
      {:fake_nerves, github: "ConnorRigby/fake_nerves"},
      # {:fake_nerves, path: "../fake_nerves", override: true},
      {:credo, "~> 0.4"},
      {:dialyxir, "~> 0.4"}]
  end

  def platform_deps("rpi3") do
    [
      {:nerves_leds, "~> 0.7.0"},
      {:elixir_ale, "~> 0.5.5"}
    ]
  end

  def platform_deps("qemu"), do: []

  def platform_apps("rpi3") do
    [ :nerves_leds,
      :elixir_ale ]
  end

  def platform_apps("qemu"), do: [:nerves_system_qemu_arm]

  def aliases(:prod) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

  def aliases(_), do: []

  # # FIXME
  # def system("rpi3") do
  #   [{:"nerves_system_rpi3",
  #     git: "https://github.com/ConnorRigby/nerves_system_rpi3.git",
  #     tag: "v0.7.5" }]
  # end

  def system("rpi3") do
    [{:"nerves_system_rpi3", path: "/home/connor/farmbot/os/nerves/nerves_system_rpi3"}]
  end
  def system("qemu"), do: [{:nerves_system_qemu_arm, github: "nerves-project/nerves_system_qemu_arm"}]
end

defmodule Mix.Tasks.Farmbot.Build do
  use Mix.Task
  @shortdoc "Builds firmware."

  def run(args) do
    System.cmd("rm", ["-rf","rel/farmbot"])
    Mix.Tasks.Deps.Get.run(args)
    Mix.Tasks.Deps.Compile.run(args)
    Mix.Tasks.Firmware.run(args)
  end
end

defmodule Mix.Tasks.Farmbot.Clean do
  use Mix.Task
  @shortdoc "Cleans environment"

  def run(_args) do
    System.cmd("rm", ["-rf","rel/bootstrapper", "_images", "_build"])
    Mix.Tasks.Deps.Clean.run(["--all"])
  end
end

defmodule Mix.Tasks.Farmbot.Release do
  use Mix.Task
  @shortdoc "Builds a release ready image."
    def run(args) do
      IO.puts "CLEANING ENVIRONMENT!"
      Mix.Tasks.Farmbot.Clean.run(args)
      IO.puts "BUILDING FARMBOT OS!"
      Mix.Tasks.Farmbot.Build.run(args)
      IO.puts "BUILDING IMAGE FILE!"
      System.cmd("fwup", ["-a",
                          "-d",
                          "_images/rpi3/farmbot.img",
                          "-i",
                          "_images/rpi3/farmbot.img",
                          "-t",
                          "complete"])
    end
end


defmodule Mix.Tasks.Farmbot.Upload do
  use Mix.Task
  @shortdoc "Uploads a file to a url"
  def run(args) do
    ip_address = System.get_env("FARMBOT_IP")
    || List.first(args)
    || "192.168.29.186" # I get to do this because i own it.
    curl_args = [
      "-T", "_images/rpi3/farmbot.fw",
      "http://#{ip_address}:8988/firmware",
      "-H", "Content-Type: application/x-firmware",
      "-H", "X-Reboot: true"]
    IO.puts("Starting upload...")
    Mix.Tasks.Farmbot.Curl.run(curl_args)
  end
end

defmodule Mix.Tasks.Farmbot.Curl do
  use Mix.Task
  @shortdoc "Uploads an image to a development target"
  def run(args) do
    args = args ++
    [ "-#" ] # CURL OPTIONS
    Port.open({:spawn_executable, "/usr/bin/curl"},
              [{:args, args},
               :stream,
               :binary,
               :exit_status,
               :hide,
               :use_stdio,
               :stderr_to_stdout])
     handle_output
  end

  def handle_output do
    receive do
      info -> handle_info(info)
    end
  end

  def handle_info({port, {:data, << <<35>>, _ :: size(568), " 100.0%">>}}) do # LAWLZ
    IO.puts("\nDONE")
    Port.close(port)
  end

  def handle_info({port, {:data, << "\r", <<35>>, _ :: size(568), " 100.0%">>}}) do # LAWLZ
    IO.puts("\nDONE")
    Port.close(port)
  end

  def handle_info({_port, {:data, << <<35>>, <<_ :: binary>> >>}}) do
    IO.write("#")
    handle_output
  end

  def handle_info({_port, {:data, << "\n", <<35>>, <<_ :: binary>> >>}}) do
    IO.write("#")
    handle_output
  end

  def handle_info({_port, {:data, << "\r", <<35>>, <<_ :: binary>> >>}}) do
    IO.write("#")
    handle_output
  end

  def handle_info({_port, {:data, _data}}) do
    # IO.puts(data)
    handle_output
  end

  def handle_info({_port, {:exit_status, 7}}) do
    IO.puts("\nCOULD NOT CONNECT TO DEVICE!")
  end

  def handle_info({_port, {:exit_status, _status}}) do
    IO.puts("\nDONE")
  end
end
