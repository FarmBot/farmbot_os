defmodule FarmbotOS.Platform.Target.SSHConsole do
  @moduledoc """
  SSH IEx console.
  """
  use GenServer
  require Logger
  alias FarmbotOS.Asset.PublicKey

  @behaviour FarmbotOS.Asset.PublicKey

  def ready? do
    is_pid(GenServer.whereis(__MODULE__))
  end

  def add_key(%PublicKey{} = public_key) do
    GenServer.cast(__MODULE__, {:add_key, public_key})
  end

  def restart_ssh do
    GenServer.cast(__MODULE__, :restart)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    port = 22

    case start_ssh(port, []) do
      {:ok, ssh} ->
        {:ok, %{ssh: ssh, port: port, public_keys: []}}

      error ->
        Logger.warn("Could not start SSH: #{inspect(error)}")
        :ignore
    end
  end

  def terminate(_, %{ssh: ssh}) do
    stop_ssh(ssh)
  end

  def handle_cast(:restart, %{ssh: ssh} = state) do
    _ = stop_ssh(ssh)

    case start_ssh(state.port, state.public_keys) do
      {:ok, ssh} ->
        {:noreply, %{state | ssh: ssh}}

      error ->
        Logger.warn("Could not start SSH: #{inspect(error)}")
        {:noreply, %{state | ssh: nil}}
    end
  end

  def handle_cast(
        {:add_key, %PublicKey{public_key: authorized_key}},
        %{ssh: ssh} = state
      ) do
    _ = stop_ssh(ssh)
    decoded_authorized_key = do_decode(authorized_key)

    case start_ssh(state.port, decoded_authorized_key) do
      {:ok, ssh} ->
        {:noreply,
         %{
           state
           | ssh: ssh,
             public_keys: [
               List.first(decoded_authorized_key) | state.public_keys
             ]
         }}

      error ->
        Logger.warn("Could not start SSH: #{inspect(error)}")
        {:noreply, %{state | ssh: nil}}
    end
  end

  defp stop_ssh(ssh) do
    erlang_ssh_mod = :ssh
    ssh && erlang_ssh_mod.stop_daemon(ssh)
  end

  defp start_ssh(port, decoded_authorized_keys)
       when is_list(decoded_authorized_keys) do
    # nerves_keys =
    #   Application.get_env(:farmbot, :authorized_keys, [])
    #   |> Enum.join("\n")

    # decoded_nerves_keys = do_decode(nerves_keys)

    cb_opts = [decoded_authorized_keys]

    # Reuse the system_dir as well to allow for auth to work with the shared
    # keys.
    ssh = :ssh

    ssh.daemon(port, [
      {:id_string, :random},
      # {:key_cb, {Nerves.Firmware.SSH.Keys, cb_opts}},
      # {:system_dir, Nerves.Firmware.SSH.Application.system_dir()},
      {:shell, {Elixir.IEx, :start, []}}
    ])
  end

  # defp do_decode(nil), do: []

  # defp do_decode(<<>>), do: []

  # defp do_decode(authorized_key) do
  #   try do
  #     :ssh_file.decode(authorized_key, :auth_keys)
  #   rescue
  #     _err ->
  #       Logger.warn("Could not decode ssh keys.")
  #       []
  #   end
  # end
end
