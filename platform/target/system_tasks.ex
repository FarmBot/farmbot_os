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
          dir = Path.join([@mount_point, "logs", DateTime.utc_now() |> DateTime.to_unix() |> to_string])
          path = Path.join([dir, "logs.txt"])
          File.mkdir_p!(dir)
          File.write!(path, data, [:sync]) |> IO.inspect(label: "WRITE #{path}")
          System.cmd("umount", [@mount_point])
          :ok
        {reason, code} ->
          IO.puts "Could not mount device #{code}: #{inspect reason}"
      end
    end
  end
end
