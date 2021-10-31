defmodule FarmbotOS.API.ImageUploader do
  @moduledoc """
  Watches a dir and uploads images in that dir.
  """
  alias FarmbotOS.BotState
  require FarmbotOS.Logger

  alias FarmbotOS.APIFetcher

  use GenServer

  @images_path "/tmp/images/"
  @checkup_time_ms 30_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def force_checkup() do
    GenServer.cast(__MODULE__, :force_checkup)
  end

  def init([]) do
    _ = File.rm_rf!(@images_path)
    _ = File.mkdir_p!(@images_path)
    {:ok, %{}, 0}
  end

  def handle_cast(:force_checkup, state) do
    FarmbotOS.Time.no_reply(state, 0)
  end

  def handle_info(:timeout, state) do
    files =
      Path.wildcard(Path.join(@images_path, "*"))
      |> Enum.filter(
        &matches_any_pattern?(&1, [~r{/tmp/images/.*(jpg|jpeg|png|gif)}])
      )

    {:noreply, state, {:continue, files}}
  end

  def handle_continue([image_filename | rest], state) do
    try_upload(image_filename)
    {:noreply, state, {:continue, rest}}
  end

  def handle_continue([], state), do: {:noreply, state, @checkup_time_ms}

  # the meta here is likely inaccurate here because of pulling the location data
  # from the cache instead of from the firmware directly. It's close enough and
  # getting data from the firmware directly would require more work than it is
  # worth
  defp try_upload(image_filename) do
    %{x: x, y: y, z: z} = BotState.fetch().location_data.position
    meta = %{x: x, y: y, z: z, name: Path.rootname(image_filename)}
    finalize(image_filename, APIFetcher.upload_image(image_filename, meta))
  end

  defp finalize(file, {:ok, %{status: s, body: _}}) when s > 199 and s < 300 do
    FarmbotOS.Logger.success(3, "Uploaded image: #{file}")
    File.rm(file)
  end

  defp finalize(fname, other) do
    FarmbotOS.Logger.error(3, "Upload Error (#{fname}): #{inspect(other)}")
  end

  # Stolen from
  # https://github.com/phoenixframework/
  #  phoenix_live_reload/blob/151ce9e17c1b4ead79062098b70d4e6bc7c7e528
  #  /lib/phoenix_live_reload/channel.ex#L27
  defp matches_any_pattern?(path, patterns) do
    path = to_string(path)

    if String.contains?(path, "~") do
      false
    else
      Enum.any?(patterns, fn pattern ->
        String.match?(path, pattern)
      end)
    end
  end
end
