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
      require Logger
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
          _ ->
            File.touch "/tmp/authorized_keys"
            :ok
        end

        :ok = tzdata_hack()
      end

      @doc """
        This needs to happen because tzdata by default polls and downloads
        things to its release dir, which is read only in nerves environments.
        to fix this we bundle the file it would normally download, and package
        it into farmbot, then copy it to a configured dir for tzdata to
        use because /tmp is read-write, we will just copy it there at every
        boot becase its easier.
      """
      def tzdata_hack do
        Logger.info ">> Hacking tzdata..."
        # File.cp "#{:code.priv_dir(:tzdata)}/release_ets/2016c.ets", "/tmp/"
        File.write "/tmp/latest_remote_poll.txt", "2017-2-14"
        File.mkdir "/tmp/release_ets"
        File.cp_r "#{:code.priv_dir(:farmbot)}/release_ets/2016j.ets", "/tmp/release_ets/2016j.ets"
        Logger.info ">> Hacked!"
        :ok
      end

      @doc false
      def factory_reset do
        :ok = format_state_part()
        :ok
      end

      defp parse_cmd({_, 0}), do: :ok
      defp parse_cmd({err, num}),
        do: raise "error doing command(#{num}): #{inspect err}"

      defp format_state_part do
        state_path =  unquote(state_path)
        # Format partition
        System.cmd("mkfs.#{unquote(fs_type)}", ["#{unquote(block_device)}", "-F"])
        # Mount it as read/write
        # NOTE(connor): is there a reason i did this in band?
        System.cmd("mount", ["-t", unquote(fs_type), "-o", "rw",
          unquote(block_device), state_path])
        # Basically a flag that says the partition is formatted.
        File.write!("#{unquote(state_path)}/.formatted", "DONT CAT ME\n")

        File.mkdir_p! "#{state_path}/farmware"
        File.mkdir_p! "#{state_path}/farmware/packages"
        File.mkdir_p! "#{state_path}/farmware/repos"
        :ok
      end
    end
  end
end
