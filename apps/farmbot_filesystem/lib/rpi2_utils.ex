defmodule Module.concat([FileSystem, Utils, :prod, "rpi2"]) do
  @moduledoc """
    FileSystem access functions.
  """
  @behaviour FileSystem.Utils
  @state_path Application.get_env(:farmbot_filesystem, :path)
  @block_device "/dev/mmcblk0p3"
  @fs_type "ext4"
  @ro_options ["-t", @fs_type, "-o", "ro,remount", @block_device, @state_path]
  @rw_options ["-t", @fs_type, "-o", "rw,remount", @block_device, @state_path]

  # mount -t ext4 -o ro,remount /dev/mmcblk0p3 /state

  @doc false
  def mount_read_only, do: "mount" |> System.cmd(@ro_options) |> parse_cmd
  @doc false
  def mount_read_write, do: "mount" |> System.cmd(@rw_options) |> parse_cmd

  @doc false
  def fs_init do
    # check if the formatted flag exists
    with {:error, _} <- File.read("#{@state_path}/.formatted") do
      # If it does, format the state partition
      :ok = format_state_part
    else
      # If not, we are fine. continue
      _ -> :ok
    end
  end

  @doc false
  def factory_reset do
    :ok = format_state_part
    :ok
  end

  defp parse_cmd({_, 0}), do: :ok
  defp parse_cmd({err, num}), do: raise "error doing command(#{num}): #{inspect err}"

  defp format_state_part do
    # Format partition
    System.cmd("mkfs.#{@fs_type}", ["#{@block_device}", "-F"])
    # Mount it as read/write
    System.cmd("mount", ["-t", @fs_type, "-o", "rw", @block_device, @state_path])
    # Basically a flag that says the partition is formatted.
    File.write!("#{@state_path}/.formatted", "DONT CAT ME\n")
    :ok
  end
end
