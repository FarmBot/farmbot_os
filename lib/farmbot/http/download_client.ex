defmodule Farmbot.HTTP.DownloadClient do
  @moduledoc """
    HTTP plugin for downloading a file.
  """

  use GenServer
  use Farmbot.DebugLog
  alias Farmbot.HTTP.Client

  def start_link(file_name) do
    GenServer.start_link(__MODULE__, file_name)
  end

  def init(file_name) do
    debug_log "[#{inspect self()}] opening #{file_name} for writing."
    {:ok, file} = :file.open(file_name, [:write, :raw])
    state = %{
      file:           file,
      file_name:      file_name,
      content_length: nil,
      content_size:   0
    }
    {:ok, state}
  end

  def handle_info({:stream_start, headers}, state) do
    content_length = maybe_content_length(headers)
    {:noreply, %{state | content_length: content_length}}
  end

  def handle_info(:stream_end, state) do
    {:stop, :normal, state}
  end

  def handle_info({:error, reason}, state), do: {:stop, reason,  state}
  def handle_info({:stream, data},  state) do
    :ok = :file.write(state.file, data)
    new_state = %{state | content_size: byte_size(data) + state.content_size}
    print_progress(new_state)
    {:noreply, new_state}
  end


  def terminate(reason, state) do
    debug_log "[#{inspect self()}] closing #{state.file_name}."
    :ok = :file.close(state.file)
  end

  defp maybe_content_length([{header, value} | _rest]) when header == 'content-length' do
    value
  end

  defp print_progress(%{content_length: nil}), do: :ok
  defp print_progress(%{content_length: total, content_size: collected}) do
    debug_log "[#{inspect self()}] #{collected} / #{total}"
  end

  defp maybe_content_length([_header | rest]), do: maybe_content_length(rest)
  defp maybe_content_length([]), do: nil
end
