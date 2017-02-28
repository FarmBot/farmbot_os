defmodule Farmbot.ImageWatcher do
  @moduledoc """
    Watches a directory on the File System and uploads images
  """
  use GenServer
  require Logger

  @images_path "/tmp/images"
  @type state :: []

  @doc """
    Starts the Image Watcher
  """
  @spec start_link :: {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc """
    Uploads all images if they exist.
  """
  @spec force_upload :: no_return
  def force_upload, do: do_checkup()

  @spec init([]) :: {:ok, any}
  def init([]) do
    # TODO(Connor) kill :fs if this app dies.
    :fs_app.start(:normal, [])
    :fs.subscribe()
    {:ok, []}
  end

  @spec handle_info(any, state) :: {:noreply, state}
  def handle_info(:checkup, []) do
    do_checkup()
    {:noreply, []}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, [:modified, :closed]}},
  state) do
    if matches_any_pattern?(path, [~r{/tmp/images/.*(jpg|jpeg|png|gif)}]) do
      do_checkup()
    end
    {:noreply, []}
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

  @spec do_checkup :: no_return
  defp do_checkup do
    images = File.ls!(@images_path)

    images
    |> Enum.all?(fn(file) ->
      path = Path.join(@images_path, file)
      case try_upload(path) do
        {:ok, _} ->
          File.rm!(path)
          :ok
        {:error, reason} ->
          {:error, reason}
        error -> {:error,  error}
      end
    end)
    |> print_thing(Enum.count(images)) # Sorry
  end

  @spec try_upload(binary) :: {:ok, any} | {:error, any}
  defp try_upload(file_path) do
    Logger.info "Image Watcher trying to upload #{file_path}"
    Farmbot.HTTP.upload_file(file_path)
  end

  @spec print_thing(boolean, integer) :: :ok
  defp print_thing(_, count) when count == 0, do: :ok
  defp print_thing(true, _count) do
    Logger.info "Image Watcher uploaded images", type: :success
    :ok
  end

  defp print_thing(false, _count) do
    Logger.warn("Image Watcher couldn't upload all images!")
    :ok
  end
end
