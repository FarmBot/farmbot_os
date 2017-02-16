defmodule Farmbot.ImageWatcher do
  @moduledoc """
    Watches a directory on the File System and uploads images
  """
  use GenServer
  require Logger

  @checkup_frequency 10_000
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
  @spec start_link :: :ok | {:error, atom}
  def force_upload, do: do_checkup()

  @spec init([]) :: {:ok, any}
  def init([]) do
    do_send()
    {:ok, []}
  end

  @spec handle_info(any, state) :: {:noreply, state}
  def handle_info(:checkup, []) do
    do_checkup()
    {:noreply, []}
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
        {:error, reason} -> {:error, reason}
        error -> {:error,  error}
      end
    end)
    |> print_thing(Enum.count(images)) # Sorry
  end

  @spec try_upload(binary) :: {:ok, any} | {:error, any}
  defp try_upload(file_path) do
    Logger.debug "Image Watcher trying to upload #{file_path}"
    Farmbot.HTTP.upload_file(file_path)
  end

  @spec print_thing(boolean, integer) :: :ok
  defp print_thing(_, count) when count == 0, do: :ok
  defp print_thing(true, _count) do
    Logger.debug "Image Watcher uploaded images", type: :success
    :ok
  end

  defp print_thing(false, _count) do
    Logger.warn("Image Watcher couldn't upload all images!")
    :ok
  end

  @spec do_send :: reference
  defp do_send, do: Process.send_after(self(), :checkup, @checkup_frequency)
end
