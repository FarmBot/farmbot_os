defmodule FileSystem.Utils do
  @moduledoc """
    A behaviour for filesystem access modules.
  """
  @type ret_val :: :ok | {:error, atom}
  @callback mount_read_only :: ret_val
  @callback mount_read_write :: ret_val
  @callback fs_init :: ret_val
  @callback factory_reset :: ret_val
end

defmodule Module.concat([FileSystem, Utils, :dev, "development"]) do
  @moduledoc """
    Spoofs Filesystem access in development mode.
  """
  @behaviour FileSystem.Utils
  @doc false
  def mount_read_only, do: :ok
  @doc false
  def mount_read_write, do: :ok
  @doc false
  def fs_init, do: :ok
  def factory_reset, do: :ok
end

defmodule Module.concat([FileSystem, Utils, :prod, "rpi3"]) do
  @moduledoc """
    FileSystem access functions.
  """
  @behaviour FileSystem.Utils
  @state_path Application.get_env(:farmbot, :state_path)
  @block_device "/dev/mmcblk0p3"
  @fs_type "ext4"
  @ro_options ["-t", @fs_type, "-o", "ro,remount", @block_device, @state_path]
  @rw_options ["-t", @fs_type, "-o", "rw,remount", @block_device, @state_path]

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
    Farmbot.reboot
  end

  defp parse_cmd({_, 0}), do: :ok

  defp format_state_part do
    # Format partition
    System.cmd("mkfs.#{@fs_type}", ["#{@block_device}", "-F"])
    # Mount it as read/write
    mount_read_write
    # Basically a flag that says the partition is formatted.
    File.write!("#{@state_path}/.formatted", "DONT CAT ME\n")
    :ok
  end
end

defmodule Module.concat([FileSystem, Utils, :prod, "qemu"]) do
  @moduledoc """
    FileSystem access functions.
  """
  @behaviour FileSystem.Utils

  @doc false
  def mount_read_only, do: :ok
  @doc false
  def mount_read_write, do: :ok

  @doc false
  def fs_init, do: :ok

  @doc false
  def factory_reset, do: Farmbot.reboot
end
