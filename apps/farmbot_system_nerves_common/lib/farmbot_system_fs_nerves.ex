defmodule Farmbot.System.NervesCommon.FileSystem do
  @moduledoc """
    Common filesystem functionality for Nerves Devices
  """

  defmacro __using__(
    target: _,
    ro_options: ro_options,
    rw_options: rw_options,
    state_path: state_path,
    fs_type:    fs_type,
    block_device: block_device)
  do
    quote do
      # mount -t ext4 -o ro,remount /dev/mmcblk0p3 /state

      @doc false
      def mount_read_only,
        do: "mount" |> System.cmd(unquote(ro_options)) |> parse_cmd
      @doc false
      def mount_read_write,
        do: "mount" |> System.cmd(unquote(rw_options)) |> parse_cmd

      @doc false
      def fs_init do
        # check if the formatted flag exists
        with {:error, _} <- File.read("#{unquote(state_path)}/.formatted") do
          # If it does, format the state partition
          :ok = format_state_part()
        else
          # If not, we are fine. continue
          _ -> :ok
        end
      end

      @doc false
      def factory_reset do
        :ok = format_state_part()
        :ok
      end

      defp parse_cmd({_, 0}), do: :ok
      defp parse_cmd({err, num}),
        do: raise "error doing command(#{num}): #{inspect err}"

      defp format_state_part() do
        # Format partition
        System.cmd("mkfs.#{unquote(fs_type)}", ["#{unquote(block_device)}", "-F"])
        # Mount it as read/write
        # NOTE(connor): is there a reason i did this in band?
        System.cmd("mount", ["-t", unquote(fs_type), "-o", "rw", unquote(block_device), unquote(state_path)])
        # Basically a flag that says the partition is formatted.
        File.write!("#{unquote(state_path)}/.formatted", "DONT CAT ME\n")
        :ok
      end
    end
  end
end
