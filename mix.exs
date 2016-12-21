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

defmodule Mix.Tasks.Farmbot do
  def env_info do
    IO.puts "[ NERVES_TARGET ]:   #{Mix.Project.config[:target]}"
    System.put_env("NERVES_TARGET", "#{Mix.Project.config[:target]}")
    if System.get_env("NERVES_SYSTEM") do
      IO.puts "[ NERVES_SYSTEM ]:   #{System.get_env("NERVES_SYSTEM")}"
    end
    IO.puts "[  ENVIRONMENT  ]:   #{Mix.env}"
    IO.puts "[   GIT HASH    ]:   #{git_revision}"
  end

  defp git_revision do
    # git log --pretty=format:'%h' -n 1
    {res, 0} = System.cmd("git", ["log", "--pretty=format:%h", "-n 1"])
    res |> String.trim
  end

  defmodule System do
    def run(_) do
      Mix.Tasks.Farmbot.env_info

      port = Port.open({:spawn, "bash ./scripts/clone_system.sh"},
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
        {^port, {:exit_status, 0}} -> IO.puts "Environment built!"
        {^port, {:exit_status, _}} -> IO.puts "Error setting up environment"
        stuff -> IO.puts "unexpected stuff: #{inspect stuff}"
      end
    end
  end

  defmodule Firmware do
    use Mix.Task
    @shortdoc "Builds firmware."

    def run(args) do
      Mix.Tasks.Farmbot.env_info
      :ok = case handle_args(args) do
        true -> do_run(args)
        _ -> :ok
      end
      if Enum.find_value(args, fn(arg) -> arg == "--upload" end) do
        if Elixir.System.get_env("BOT_IP_ADDR") == nil do
          Elixir.System.put_env("BOT_IP_ADDR", "192.168.24.1")
        end
        ip = Elixir.System.get_env("BOT_IP_ADDR")
        port = Port.open({:spawn, "bash ./scripts/upload.sh"},
          [:stream,
           :binary,
           :exit_status,
           :hide,
           :use_stdio,
           :stderr_to_stdout])
        handle_port(port, "Uploaded!", "Failed to upload!")
      end
    end

    def check_system_dir do
      {:ok, dirs} = File.ls "./apps/"
      Enum.find(dirs, fn(dir) ->
        String.contains?(dir, "NERVES_SYSTEM")
      end)
    end

    def do_run(_args) do
      maybe_system_dir = check_system_dir
      if maybe_system_dir &&  Elixir.System.get_env("NERVES_SYSTEM") == nil do
        IO.puts "detected a system build: #{maybe_system_dir}, set the NERVES_SYSTEM env var to use it."
      end

      if !File.exists?("./deps") do
        fetch_deps
      end

      port = Port.open({:spawn, "bash ./scripts/build.sh"},
        [:stream,
         :binary,
         :exit_status,
         :hide,
         :use_stdio,
         :stderr_to_stdout])
      handle_port(port, "Built firmware!", "Error building firmware!")
    end
    def handle_port(port, success, err) do
      receive do
        {^port, {:data, data}} -> IO.puts data; handle_port(port, success, err)
        {^port, {:exit_status, 0}} -> IO.puts success; :ok
        {^port, {:exit_status, _}} -> IO.puts err; :error
        stuff -> IO.puts "unexpected stuff: #{inspect stuff}"; :error
      end
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
    def do_thing("--upload"), do: true
    def do_thing("--burn"), do: true
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
        * BOT_IP_ADDR    (optional)       - the ip address of a running farmbot. This is used in the upload task.
      Can also be configured by several command line switches.
        * --clean   - will clean the environment before building again. (this can take a while)
        * --upload  - If the build succeeds, upload firmware to IP_ADDRESS
        * --deps    - force fetch dependencies.
        * --nobuild - don't actually build the firmware.
        * --burn    - burn the image to an sdcard
        * --help    - display this message.
    """
  end
end
