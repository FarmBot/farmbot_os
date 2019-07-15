defmodule FarmbotExt.API.ImageUploader do
  @moduledoc """
  Watches a dir and uploads images in that dir.
  """
  alias FarmbotCore.BotState
  require FarmbotCore.Logger

  alias FarmbotExt.API

  use GenServer

  @images_path "/tmp/images/"
  @checkup_time_ms 30_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def force_checkup do
    GenServer.cast(__MODULE__, :force_checkup)
  end

  def init([]) do
    _ = File.rm_rf!(@images_path)
    _ = File.mkdir_p!(@images_path)
    {:ok, %{}, 0}
  end

  def handle_cast(:force_checkup, state) do
    {:noreply, state, 0}
  end

  def handle_info(:timeout, state) do
    files =
      Path.wildcard(Path.join(@images_path, "*"))
      |> Enum.filter(&matches_any_pattern?(&1, [~r{/tmp/images/.*(jpg|jpeg|png|gif)}]))

    {:noreply, state, {:continue, files}}
  end

  def handle_continue([image_filename | rest], state) do
    try_upload(image_filename)
    {:noreply, state, {:continue, rest}}
  end

  def handle_continue([], state), do: {:noreply, state, @checkup_time_ms}

  # TODO(Connor) the meta here is likely inaccurate.
  defp try_upload(image_filename) do
    %{x: x, y: y, z: z} = BotState.fetch().location_data.position
    meta = %{x: x, y: y, z: z}

    with {:ok, %{status: s, body: _body}} when s > 199 and s < 300 <-
           API.upload_image(image_filename, meta) do
      FarmbotCore.Logger.success(3, "Uploaded image: #{image_filename}")
      File.rm(image_filename)
    end
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
