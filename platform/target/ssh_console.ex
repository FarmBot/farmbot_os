defmodule Farmbot.Target.SSHConsole do
  @moduledoc """
  SSH IEx console.
  """
  use GenServer
  import Farmbot.System.ConfigStorage, only: [get_config_value: 3]
  use Farmbot.Logger

  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_) do
    port = get_config_value(:float, "settings", "ssh_port") |> round()
    authorized_key = get_config_value(:string, "settings", "authorized_ssh_key")
    decoded_authorized_key = do_decode(authorized_key)
    ssh = start_ssh(port, decoded_authorized_key)
    {:ok, %{ssh: ssh}}

  end

  def terminate(_, %{ssh: ssh}) do
    :ssh.stop_daemon(ssh)
  end

  defp start_ssh(port, decoded_authorized_keys) when is_list(decoded_authorized_keys) do
    # Reuse keys from `nerves_firmware_ssh` so that the user only needs one
    # config.exs entry.
    nerves_keys = Application.get_env(:nerves_firmware_ssh, :authorized_keys, []) |> Enum.join("\n")
    decoded_nerves_keys = do_decode(nerves_keys)

    cb_opts = [authorized_keys: decoded_nerves_keys ++ decoded_authorized_keys]

    # Reuse the system_dir as well to allow for auth to work with the shared
    # keys.
    {:ok, ssh} =
      :ssh.daemon(port, [
        {:id_string, :random},
        {:key_cb, {Nerves.Firmware.SSH.Keys, cb_opts}},
        {:system_dir, Nerves.Firmware.SSH.Application.system_dir()},
        {:shell, {Elixir.IEx, :start, []}}
      ])

    ssh
  end

  defp do_decode(nil), do: []

  defp do_decode(authorized_key) do
    try do
      :public_key.ssh_decode(authorized_key, :auth_keys)
    rescue
      _err ->
        Logger.warn 3, "Could not decoded ssh keys."
        []
    end
  end
end
