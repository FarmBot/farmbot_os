defmodule Module.concat([Farmbot, System, "host", FileSystem]) do
  @moduledoc false
  @behaviour Farmbot.System.FS

  def fs_init do
    path = Application.get_env(:farmbot, :path)
    File.mkdir_p!(path)
    :ok
  end

  def mount_read_only, do: :ok
  def mount_read_write, do: :ok
end
