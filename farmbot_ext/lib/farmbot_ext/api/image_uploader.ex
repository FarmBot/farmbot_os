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
    {:ok, %{}, 0}
  end

  def handle_cast(:force_checkup, state) do
    {:noreply, state, 0}
  end

  def handle_info(:timeout, state) do
    files = Path.wildcard(Path.join(@images_path, "*.jpg"))
    {:noreply, state, {:continue, files}}
  end

  def handle_continue([image_filename | rest], state) do
    try_upload(image_filename)
    {:noreply, state, {:continue, rest}}
  end

  def handle_continue([], state), do: {:noreply, state, @checkup_time_ms}

  # TODO(Connor) the meta here is likely inaccurate.
  defp try_upload(image_filename) do
    meta = BotState.fetch().location_data.position

    with {:ok, %{status: s, body: body}} when s > 199 and s < 300 <-
           API.upload_image(image_filename, meta) do
      FarmbotCore.Logger.success(3, "Uploaded image: #{inspect(body)}")
      File.rm(image_filename)
    end
  end
end
