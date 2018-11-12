defmodule Farmbot.BootState do
  @data_path Farmbot.OS.FileSystem.data_path()
  @state_file Path.join(@data_path, "boot_state")

  def read do
    case File.read(@state_file) do
      {:error, :enoent} -> write(:NEEDS_CONFIGURATION)
      {:error, _} = er -> er
      {:ok, data} -> data |> String.trim() |> String.to_atom()
    end
  end

  def write(status)
    when status in [:NEEDS_CONFIGURATION, :CONFIGURATIONFAIL, :UPANDRUNNING] do
      File.write(@state_file, to_string(status) <> "\r\n")
      status
    end
end
