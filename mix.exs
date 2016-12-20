defmodule FarmbotOs.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     target: target(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps, do: [{:httpotion, "~> 3.0.0"}]

  defp target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
  defp target(_), do: System.get_env("NERVES_TARGET") || "development"
end

defmodule Mix.Tasks.Farmbot.Firmware do
  use Mix.Task
  @shortdoc "Builds firmware."

  def run(args) do
    case handle_args(args) do
      true -> do_run(args)
      _ -> :ok
    end
  end

  def do_run(_args) do
    if Mix.env == :dev do
      IO.puts ">> BE CAREFUL BUILDING FIRMWARE IN DEVELOPMENT MODE, THINGS GET WEIRD. <<"
    end
    IO.puts "Building Farmbot firmware!"
    IO.puts "[ NERVES_TARGET ]:   #{Mix.Project.config[:target]}"
    if System.get_env("NERVES_SYSTEM") do
      IO.puts "[ NERVES_SYSTEM ]: #{System.get_env("NERVES_SYSTEM")}"
    end
    IO.puts "[  ENVIRONMENT  ]:   #{Mix.env}"
    IO.puts "[   GIT HASH    ]:   #{git_revision}"

    if !File.exists?("./deps") do
      fetch_deps
    end

    port = Port.open({:spawn, "bash ./apps/os/build.sh"},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout])
       handle_port(port)
  end
  def handle_port(port) do
    receive do
      {^port, {:data, data}} -> IO.puts data; handle_port(port)
      {^port, {:exit_status, 0}} -> IO.puts "Built firmware!"
      {^port, {:exit_status, _}} -> IO.puts "Error building firmwre!"
      stuff -> IO.puts "unexpected stuff: #{inspect stuff}"
    end
  end

  defp git_revision do
    # git log --pretty=format:'%h' -n 1
    {res, 0} = System.cmd("git", ["log", "--pretty=format:%h", "-n 1"])
    res |> String.trim
  end

  defp fetch_deps do
    IO.puts "Fetching dependencies."
    Mix.Tasks.Deps.Get.run([])
    true
  end

  def handle_args(args) do
    Enum.all?(args, fn(arg) ->
      do_thing(arg)
    end)
  end
  # Because reasons.
  def do_thing("-h"), do: do_thing("--help")
  def do_thing("--help") do
    IO.puts help_text
    false
  end

  def do_thing("--clean") do
    IO.puts "cleaning environment!"
    File.rm_rf("deps")
    File.rm_rf("_build")
    File.rm_rf("_images")
  end

  def do_thing("--nobuild"), do: false
  def do_thing("--deps"), do: fetch_deps

  def do_thing(other) do
    IO.puts "bad argument: #{other}"
    IO.puts help_text
    false
  end

  defp help_text, do:
  """
    Builds a farmbot firmware image.
    Can be configured by various env vars.
      * NERVES_TARGET  (default: rpi3)  - can be "rpi3", "qemu-arm" right now. More support coming soon.
      * NERVES_SYSTEM  (optional)       - can be used to not use the default system for your NERVES_TARGET
      * IP_ADDR        (optional)       - the ip address of a running farmbot. This is used in the upload task.
    Can also be configured by several command line switches.
      * --clean   - will clean the environment before building again. (this can take a while)
      * --upload  - If the build succeeds, upload firmware to IP_ADDRESS
      * --deps    - force fetch dependencies.
      * --nobuild - don't actually build the firmware.
      * --help    - display this message.
  """
end
