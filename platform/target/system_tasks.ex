defmodule Farmbot.Target.SystemTasks do
  @moduledoc "Target implementation for System Tasks."

  @behaviour Farmbot.System
  @block_device "/dev/sda1"
  @mount_point "/tmp/log_dev"

  def factory_reset(reason) do
    reboot(reason)
  end

  def reboot(_reason) do
    Nerves.Runtime.reboot()
  end

  def shutdown(_reason) do
    Nerves.Runtime.poweroff()
  end

  def stop(data) do
    System.cmd("umount", [@mount_point])
    if File.exists?(@block_device) do
      IO.puts "Found Block device #{@block_device}"
      File.mkdir_p!(@mount_point)
      case System.cmd("mount", [@block_device, @mount_point]) do
        {_, 0} ->
          File.write(Path.join([@mount_point, "logs", DateTime.utc_now() |> to_string(), "logs.txt"]), data, [:sync])
          System.cmd("umount", [@mount_point])
          :ok
        {reason, code} ->
          IO.puts "Could not mount device #{code}: #{inspect reason}"
      end
    end
  end
end
