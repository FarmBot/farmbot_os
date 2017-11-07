defmodule Farmbot.HTTP.ImageUploader do
  @moduledoc """
  Watches a directory on the File System and uploads images
  """
  use GenServer
  use Farmbot.Logger

  @images_path "/tmp/images/"

  @doc """
  Starts the Image Watcher
  """
  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    File.rm_rf!(@images_path)
    File.mkdir_p!(@images_path)
    :fs_app.start(:normal, [])
    :fs.subscribe()
    Process.flag(:trap_exit, true)
    {:ok, %{uploads: %{}}}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, [:modified, :closed]}}, state) do
    if matches_any_pattern?(path, [~r{/tmp/images/.*(jpg|jpeg|png|gif)}]) do
      [x, y, z] = [-9000, -9000, -9000]
      #FIXME
      meta = %{x: x, y: y, z: z}
      pid = spawn(__MODULE__, :upload, [state.http, path, meta])
      {:noreply, %{state | uploads: Map.put(state.uploads, pid, {path, meta, 0})}}
    else
      {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, reason}, state) do
    case state.uploads[pid] do
      nil ->
        {:noreply, state}

      {path, _meta, 6 = ret} ->
        Logger.error(2, "Failed to upload #{path} #{ret} times. Giving up.")
        File.rm(path)
        {:noreply, %{state | uploads: Map.delete(state.uploads, pid)}}

      {path, meta, retries} ->
        Logger.warn(2, "Failed to upload #{path} #{inspect(reason)}. Going to retry.")
        Process.sleep(1000 * retries)
        new_pid = spawn(__MODULE__, :upload, [path, meta])

        new_uploads =
          state
          |> Map.delete(pid)
          |> Map.put(new_pid, {path, meta, retries + 1})

        {:noreply, %{state | uploads: new_uploads}}
    end
  end

  def handle_info(_, state), do: {:noreply, state}

  # Stolen from
  # https://github.com/phoenixframework/
  #  phoenix_live_reload/blob/151ce9e17c1b4ead79062098b70d4e6bc7c7e528
  #  /lib/phoenix_live_reload/channel.ex#L27
  defp matches_any_pattern?(path, patterns) do
    path = to_string(path)

    Enum.any?(patterns, fn pattern ->
      String.match?(path, pattern)
    end)
  end

  def upload(file_path, meta) do
    Logger.busy(3, "Image Watcher trying to upload #{file_path}", type: :busy)
    Farmbot.HTTP.upload_file(file_path, meta)
    File.rm!(file_path)
    Logger.success(3, "Image Watcher uploaded #{file_path}", type: :success)
  end
end
