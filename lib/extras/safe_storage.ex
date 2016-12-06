defmodule SafeStorage do
  @moduledoc """
    I don't want to use ext4 so this happened.
    This app makes timed strategic writes to the fat32 filesystem.
    It keeps the partition mounted read only for most of the time but for a brief
    moment it will mount read/write, write a bunch of binaries, sync, then
    mount read only again.
    It only stores and returns binaries.
  """
  require Logger
  use GenServer
  @state_path Application.get_env(:farmbot, :state_path)
  @block_device "/dev/mmcblk0p3"
  @fs_type "ext4"
  @env Mix.env

  def init(_) do
    mount_read_only
    Process.sleep(10)
    case File.read("#{@state_path}/STATE") do
      {:ok, contents} ->
        # Log somethingdebug("Loading last state.")
        last_state = :erlang.binary_to_term(contents)
        {:ok, save(last_state) }
      _ ->
      # Log somethingdebug("Loading #{__MODULE__} new state.")
      {:ok, save(%{})}
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_cast({:write, {module, binary}}, state) do
    {:noreply, Map.put(state, module, binary)}
  end

  def handle_call({:read, module, is_term}, _from, state) do
    reply =
    case Map.get(state, module, nil) do
      nil -> nil
      binary ->
        if(is_term == true) do
          {:ok, :erlang.binary_to_term(binary) }
        else
          {:ok, binary}
        end
    end
    {:reply, reply, state }
  end

  def handle_info(:save, state) do
    save(state)
    {:noreply, state}
  end

  @doc """
    Writes a binary under given module key.
  """
  def write(module, binary) when is_binary(binary) do
    GenServer.cast(__MODULE__, {:write, {module, binary}})
  end

  @doc """
    Reads whatever is stored  under module key.
    is_term is a boolean. If set to true (default) it will try
    to :erlang.binary_to_term if it is false, it just returns the raw binary
  """
  def read(module, is_term\\ true) do
    GenServer.call(__MODULE__, {:read, module, is_term})
  end

  def mount_read_only() do
    if @env == :prod do
      sync
      cmd = "mount"
      System.cmd(cmd, ["-t", @fs_type, "-o", "ro,remount", @block_device, @state_path])
      |> print_cmd(cmd)
    end
  end

  def mount_read_write() do
    if @env == :prod do
      cmd = "mount"
      System.cmd(cmd, ["-t", @fs_type, "-o", "rw,remount", @block_device, @state_path])
      |> print_cmd(cmd)
    end
  end

  def sync() do
    if @env == :prod do
      sync_cmd = "sync"
      System.cmd(sync_cmd,[])
      |> print_cmd(sync_cmd)
    end
  end

  # checks if the new state is different than the old state.
  # returns true if we they are different
  defp check_old(state) do
    case File.read("#{@state_path}/STATE") do
      {:ok, contents} ->
        :erlang.binary_to_term(contents) == state
      _ -> false
    end
  end

  def save(state) do
    if(check_old(state) == false) do
      # Log somethingwarn("BE CAREFUL FILESYSTEM IS READ WRITE")
      mount_read_write
      File.write("#{@state_path}/STATE", :erlang.term_to_binary(state))
      sync
      mount_read_only
      # Log somethingdebug("FILESYSTEM SAFE AGAIN")
    end
    Process.send_after(__MODULE__, :save, 60000)
    state
  end

  defp print_cmd({result, 0}, _cmd) do
    result
  end

  defp print_cmd({result, err_no}, cmd) do
    # Log somethingerror("Something bad happened. \"#{cmd}\" exited with error code: #{err_no} and result: #{result}")
    result
  end

  def terminate(:normal, state) do
    mount_read_write
    File.write("#{@state_path}/STATE", :erlang.term_to_binary(state))
    sync
    mount_read_only
    :ok
  end

  def terminate(:reset, _state) do
    System.cmd("umount", [@block_device])
    Farmbot.format_state_part
    File.rm("#{@state_path}/STATE")
    :reset
  end
end
