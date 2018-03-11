defmodule Farmbot.System.Profile do
  @moduledoc File.read!("docs/PROFILES.md")
  use GenServer
  use Farmbot.Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    profile = Application.get_env(:farmbot, :profile) || System.get_env("FBOS_PROFILE")
    if profile do
      try do
        do_load_profiles(profile)

      rescue
        error ->
          IO.warn "Failed to load profile #{profile}: #{inspect Exception.message(error)}\n\n"
      end
    end
    :ignore
  end

  def profile_dir do
    case Farmbot.Project.target() do
      "host" ->
        path = Path.join(["overlay", "profiles"])
        Path.mkdir_p!(path)
        path
      _ -> "/profiles"
    end
  end

  defp do_load_profiles(bin) do
    profiles = String.split(bin, ",")
    for profile <- profiles do
      Logger.busy 1, "Loading profile: #{profile}"
      Code.eval_file("#{profile}.exs", profile_dir())
      Logger.success 1, "Profile #{profile} loaded."
    end
  end
end
