defmodule Farmbot.FileSystem do
  @moduledoc """
    Handles filesystem reads and writes
  """
  defmodule File do
    @moduledoc """
      Farmbot's FileSystem access. Should hopefully mimic STDLIB.
    """
    require Logger

    # I bet there is a more clever way of doing this.
    def read(path), do: Elixir.File.read(path)
    def read!(path), do: Elixir.File.read!(path)

    @doc """
      Writes a file to path on Farmbot's FileSystem.
    """
    @lint false
    def write(path, contents) do
      :ok = Farmbot.FileSystem.Handler.mount_read_write
      r = Elixir.File.write(path, contents)
      :ok = Farmbot.FileSystem.Handler.mount_read_write
      r
    end

    @doc """
      Same as write\1 but raises an exception if there is an error.
    """
    @lint false
    def write!(path, contents) do
      :ok = Handler.mount_read_write
      r = Elixir.File.write!(path, contents)
      :ok = Farmbot.FileSystem.Handler.mount_read_write
      r
    end
  end


  defmodule Handler do
    @moduledoc """
      I HAVE NO _IDEA WHAT IM DOING
    """
    @state_path Application.get_env(:farmbot, :state_path)
    @block_device "/dev/mmcblk0p3"
    @fs_type "ext4"

    require Logger
    use GenServer
    def start_link(env) do
      GenServer.start_link(__MODULE__, env, name: __MODULE__)
    end

    def init(_env) do
      Logger.debug ">> is starting file system services."
      {:ok, %{}}
    end

    def mount_read_only do
      :ok
    end

    def mount_read_write do
      :ok
    end

    # def mount_read_only() do
    #   if @env == :prod do
    #     sync
    #     cmd = "mount"
    #     cmd
    #     |> System.cmd(["-t",
    #                    @fs_type,
    #                    "-o",
    #                    "ro,remount",
    #                    @block_device, @state_path])
    #     |> print_cmd(cmd)
    #   end
    # end
    #
    # def mount_read_write() do
    #   if @env == :prod do
    #     cmd = "mount"
    #     cmd
    #     |> System.cmd(["-t",
    #                    @fs_type,
    #                    "-o",
    #                    "rw,remount",
    #                    @block_device, @state_path])
    #     |> print_cmd(cmd)
    #   end
    # end
    #
    # def sync() do
    #   if @env == :prod do
    #     sync_cmd = "sync"
    #     sync_cmd
    #     |> System.cmd([])
    #     |> print_cmd(sync_cmd)
    #   end
    # end

    # defp print_cmd({result, 0}, _cmd) do
    #   result
    # end
    #
    # defp print_cmd({result, err_no}, cmd) do
    #   Logger.error """
    #     >> encountered an error
    #       executing: #{inspect cmd}: (#{err_no}) #{inspect result}
    #     """,
    #     channels: [:toast]
    #   result
    # end

  end
end
