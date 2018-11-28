defmodule Farmbot.Target.TzdataTask do
  use GenServer

  @data_path Farmbot.OS.FileSystem.data_path()
  # 20 minutes
  @default_timeout_ms round(1.2e+6)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([]) do
    {:ok, nil, 0}
  end

  def handle_info(:do_checkup, state) do
    dir = Path.join(@data_path, "tmp_downloads")

    if File.exists?(dir) do
      for obj <- File.ls!(dir) do
        File.rm_rf!(Path.join(dir, obj))
      end
    end

    {:noreply, state, @default_timeout_ms}
  end
end
