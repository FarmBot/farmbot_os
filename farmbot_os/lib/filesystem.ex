defmodule Farmbot.OS.FileSystem do
  @data_path Application.get_env(:farmbot, __MODULE__)[:data_path]
  @data_path || Mix.raise("""
    config :farmbot, Farmbot.OS.Filesystem,
      data_path: "/path/to/folder"
  """)

  def data_path, do: @data_path
end
