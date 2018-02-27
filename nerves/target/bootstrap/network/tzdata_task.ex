defmodule Farmbot.Target.Network.TzdataTask do
  use GenServer

  @fb_data_dir Path.join(Application.get_env(:farmbot, :data_path), "tmp_downloads")
  @timer_ms round(1.2e+6) # 20 minutes

  def start_link(_, _) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    send self(), :do_checkup
    {:ok, nil, :hibernate}
  end

  def handle_info(:do_checkup, _) do
    dir = @fb_data_dir
    if File.exists?(dir) do
      for obj <- File.ls!(dir) do
        File.rm_rf!(Path.join(dir, obj))
      end
    end
    {:noreply, restart_timer(self()), :hibernate}
  end

  defp restart_timer(pid) do
    Process.send_after pid, :do_checkup, @timer_ms
  end

end
