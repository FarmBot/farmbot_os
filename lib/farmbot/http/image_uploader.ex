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
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    Logger.debug 3, "Ensuring #{@images_path} exists."
    Application.stop(:fs)
    Application.put_env(:fs, :path, @images_path)
    File.rm_rf!   @images_path
    File.mkdir_p! @images_path
    :fs_app.start(:normal, [])
    :fs.subscribe()
    Process.flag(:trap_exit, true)
    {:ok, %{uploads: %{}}}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, _}}, state) do
    matches? = matches_any_pattern?(path, [~r{/tmp/images/.*(jpg|jpeg|png|gif)}])
    already_uploading? = Enum.find(state.uploads, fn({_pid, {find_path, _meta, _count}}) ->
      find_path == path
    end) |> is_nil() |> Kernel.!()
    if matches? and (not already_uploading?) do
      Logger.info 2, "Uploading: #{path}"
      %{x: x, y: y, z: z} = Farmbot.BotState.get_current_pos()
      meta = %{x: x, y: y, z: z}
      pid = spawn __MODULE__, :upload, [path, meta]
      {:noreply, %{state | uploads: Map.put(state.uploads, pid, {path, meta, 0})}}
    else
      # Logger.warn 3, "Not uploading: match: #{matches?} already_uploading?: #{already_uploading?}"
      {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, reason}, state) do
    case state.uploads[pid] do
      nil                   -> {:noreply, state}
      {path, _meta, 6 = ret} ->
        Logger.error 1, "Failed to upload #{path} #{ret} times. Giving up."
        File.rm path
        {:noreply, %{state | uploads: Map.delete(state.uploads, pid)}}
      {path, meta, retries}  ->
        Logger.warn 2, "Failed to upload #{path} #{inspect reason}. Going to retry."
        Process.sleep(1000 * retries)
        new_pid = spawn __MODULE__, :upload, [path, meta]
        new_uploads = state
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
    if String.contains?(path, "~") do
      false
    else
      Enum.any?(patterns, fn pattern ->
        String.match?(path, pattern)
      end)
    end
  end

  @spec upload(Path.t, map) :: {:ok, any} | {:error, any}
  def upload(file_path, meta) do
    Logger.busy 3, "Image Watcher trying to upload #{file_path}"
    Farmbot.HTTP.upload_file(file_path, meta)
    if Process.whereis(Farmbot.System.Updates.SlackUpdater) do
      Farmbot.System.Updates.SlackUpdater.upload_file(file_path)
    end
    File.rm!(file_path)
    Logger.success 3, "Image Watcher uploaded #{file_path}"
  end
end
