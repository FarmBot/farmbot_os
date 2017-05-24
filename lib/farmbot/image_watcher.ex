defmodule Farmbot.ImageWatcher do
  @moduledoc """
    Watches a directory on the File System and uploads images
  """
  use GenServer
  require Logger
  alias Farmbot.Context

  @images_path "/tmp/images"
  @type state :: []

  @doc """
    Starts the Image Watcher
  """
  def start_link(%Context{} = ctx, opts),
    do: GenServer.start_link(__MODULE__, ctx, opts)

  @doc """
    Uploads all images if they exist.
  """
  @spec force_upload(Context.t) :: no_return
  def force_upload(%Context{} = ctx), do: do_checkup(ctx)

  def init(context) do
    # TODO(Connor) kill :fs if this app dies.
    :fs_app.start(:normal, [])
    :fs.subscribe()
    {:ok, %{context: context}}
  end

  def handle_info(:checkup, state) do
    do_checkup(state.context)
    {:noreply, state}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, [:modified, :closed]}},
  state) do
    if matches_any_pattern?(path, [~r{/tmp/images/.*(jpg|jpeg|png|gif)}]) do
      do_checkup(state.context)
    end
    {:noreply, state}
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

  @spec do_checkup(Context.t) :: no_return
  defp do_checkup(%Context{} = context) do
    images = File.ls!(@images_path)

    images
    |> Enum.all?(fn(file) ->
      path = Path.join(@images_path, file)
      case try_upload(context, path) do
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

  @spec try_upload(Context.t, binary) :: {:ok, any} | {:error, any}
  defp try_upload(%Context{} = ctx, file_path) do
    Logger.info "Image Watcher trying to upload #{file_path}"
    Farmbot.HTTP.upload_file!(ctx, file_path)
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
