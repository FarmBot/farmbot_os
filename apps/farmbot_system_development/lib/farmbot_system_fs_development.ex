defmodule Module.concat([Farmbot, System, "development", FileSystem]) do
  @moduledoc false
  @behaviour Farmbot.System.FS
  def fs_init, do: :ok
  def mount_read_only, do: :ok
  def mount_read_write, do: :ok
end
