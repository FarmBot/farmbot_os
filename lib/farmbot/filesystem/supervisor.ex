defmodule Farmbot.FileSystem.Supervisor do
  @moduledoc """
      Supervises the filesystem storage
  """
  @state_path Application.get_env(:farmbot, :state_path)

  use Supervisor
  require Logger
  alias Farmbot.FileSystem.ConfigStorage
  alias Farmbot.FileSystem.StateStorage
  alias Farmbot.FileSystem.Handler

  def start_link(env), do: Supervisor.start_link(__MODULE__, env)
  def init(env) do
    Logger.debug ">> is initializing its's filesystem."
    # We need to make sure that our application data partition isnt currupted.
    {:ok, _} = fs_init(env)
    # File system is still read/write right now.
    children = [
      worker(Handler, [env],    restart: :permanent),
      worker(ConfigStorage, [], restart: :permanent),
      worker(StateStorage,  [], restart: :permanent)
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)
  end

  @spec format_state_part :: {:ok, atom}
  defp format_state_part do
    Logger.warn ">>'s filesystem is being formatted.'"
    # Format partition
    System.cmd("mkfs.ext4", ["/dev/mmcblk0p3", "-F"])
    # Mount it as read/write # TODO: Probably make this not hard coded.
    System.cmd("mount", ["/dev/mmcblk0p3", "#{@state_path}", "-t", "ext4"])
    # Basically a flag that says the partition is formatted.
    File.write!("#{@state_path}/.formatted", "DONT CAT ME\n")
    {:ok, :pattern_matching_is_hard}
  end

  @spec fs_init(:prod) :: {:ok, any}
  defp fs_init(:prod) do
    # check if the formatted flag exists
    with {:error, _} <- File.read("#{@state_path}/.formatted") do
      format_state_part
    end
  end

  @spec fs_init(any) :: {:ok, :development}
  defp fs_init(_) do
    {:ok, :development}
  end

  @doc """
    Factory resets
  """
  def factory_reset do
    # TODO: Fix factory reset
    :TODO
  end
end
