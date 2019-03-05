defmodule FarmbotOS.Platform.Target.SSHConsole do
  @moduledoc """
  SSH IEx console.
  """
  use GenServer
  import FarmbotCore.Config, only: [get_config_value: 3]
  require FarmbotCore.Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    port = get_config_value(:float, "settings", "ssh_port") |> round()
    authorized_key = get_config_value(:string, "settings", "authorized_ssh_key")
    decoded_authorized_key = do_decode(authorized_key)

    case start_ssh(port, decoded_authorized_key) do
      {:ok, ssh} ->
        {:ok, %{ssh: ssh}}

      _ ->
        FarmbotCore.Logger.warn(1, "Could not start SSH.")
        :ignore
    end
  end

  def terminate(_, %{ssh: ssh}) do
    :ssh.stop_daemon(ssh)
  end

  defp start_ssh(port, decoded_authorized_keys) when is_list(decoded_authorized_keys) do
    # Reuse keys from `nerves_firmware_ssh` so that the user only needs one
    # config.exs entry.
    nerves_keys =
      Application.get_env(:nerves_firmware_ssh, :authorized_keys, []) |> Enum.join("\n")

    decoded_nerves_keys = do_decode(nerves_keys)

    cb_opts = [authorized_keys: decoded_nerves_keys ++ decoded_authorized_keys]

    # Reuse the system_dir as well to allow for auth to work with the shared
    # keys.
    :ssh.daemon(port, [
      {:id_string, :random},
      {:key_cb, {Nerves.Firmware.SSH.Keys, cb_opts}},
      {:system_dir, Nerves.Firmware.SSH.Application.system_dir()},
      {:shell, {Elixir.IEx, :start, []}}
    ])
  end

  defp do_decode(nil), do: []

  defp do_decode(<<>>), do: []

  defp do_decode(authorized_key) do
    try do
      :public_key.ssh_decode(authorized_key, :auth_keys)
    rescue
      _err ->
        FarmbotCore.Logger.warn(3, "Could not decode ssh keys.")
        []
    end
  end
end
