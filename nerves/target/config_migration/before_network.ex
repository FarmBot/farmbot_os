defmodule Farmbot.Target.ConfigMigration.BeforeNetwork do
  @moduledoc "Init module for migrating the old JSON based config."
  use GenServer
  alias Farmbot.System.ConfigStorage
  use Farmbot.Logger

  @data_path Application.get_env(:farmbot, :data_path)

  @doc false
  def start_link(_, _) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do

    old_farmware_dir = Path.join(@data_path, "farmware")
    old_config_json_file = Path.join(@data_path, "config.json")
    old_secret_file = Path.join(@data_path, "secret")

    if File.exists?(old_config_json_file) do
      File.rm_rf(old_farmware_dir)
      Logger.busy 1, "Migrating json based config."
      with :ok <- migrate_config_file(old_config_json_file),
           :ok <- migrate_secret(old_secret_file),
           _   <- migrate_fw()
      do
        Logger.success 1, "Successfully migrated."
        :ignore
      else
        {:error, step, sub_step, reason} ->
          msg = "Migration failed at step: #{step} substep: #{sub_step} reason: #{inspect reason}"
          Logger.error 1, msg
          {:stop, msg}
      end
    else
      :ignore
    end
  end

  def migrate_fw do
    hw = ConfigStorage.get_config_value(:string, "settings", "firmware_hardware")
    Farmbot.Firmware.UartHandler.Update.maybe_update_firmware(hw)
  end

  def migrate_config_file(filename) do
    with {:file_read, {:ok, file}} <- {:file_read,     File.read(filename)},
    {:json_decode,    {:ok, data}} <- {:json_decode,   Poison.decode(file)},
    {:authorization,  {:ok, auth}} <- {:authorization, Map.fetch(data, "authorization")},
    {:authorization,  :ok}         <- {:authorization, migrate_auth(auth)},
    {:configuration,  {:ok, conf}} <- {:configuration, Map.fetch(data, "configuration")},
    {:configuration,  :ok}         <- {:configuration, migrate_configuration(conf)},
    {:hardware,       {:ok, hw  }} <- {:hardware,      Map.fetch(data, "hardware")},
    {:hardware,       :ok}         <- {:hardware,      migrate_hw(hw)},
    {:network,        {:ok, net }} <- {:network,       Map.fetch(data, "network")},
    {:network,        :ok}         <- {:network,       migrate_network(net)} do
      Logger.success 1, "JSON config migrated"
      :ok
    else
      {step, {:error, reason}} -> {:error, :migrate_config_file, step, reason}
    end
  end

  def migrate_secret(filename) do
    with {:ok, bin_term} <- File.read(filename) do
      bin = :erlang.binary_to_term(bin_term)
      ConfigStorage.update_config_value(:string, "authorization", "password", bin)
      File.rm(filename)
    else
      {:error, reason} ->
        {:error, :migrate_secret_file,  :file_read, reason}
    end
  end

  defp migrate_auth(%{"server" => server}) do
    ConfigStorage.update_config_value(:string, "authorization", "server", server)
  end

  defp migrate_configuration(%{"firmware_hardware" => hw,
    "first_party_farmware" => fpf,
    "os_auto_update" => os_auto_update,
    "timezone" => tz, "user_env" => user_env})
  do
    import ConfigStorage, only: [update_config_value: 4]
    with {:first_party_farmware, :type_check, true}    <- {:first_party_farmware, :type_check, is_boolean(fpf)},
    {:first_party_farmware, :update_config_value, :ok} <- {:first_party_farmware, :update_config_value, update_config_value(:bool, "settings", "first_party_farmware", fpf)},
    {:firmware_hardware, :type_check, true}            <- {:firmware_hardware, :type_check, hw in ["arduino", "farmduino"]},
    {:firmware_hardware, :update_config_value, :ok}    <- {:firmware_hardware, :update_config_value, update_config_value(:string, "settings", "firmware_hardware", hw)},
    {:os_auto_update, :type_check, true}               <- {:os_auto_update, :type_check, is_boolean(os_auto_update)},
    {:os_auto_update, :update_config_value, :ok}       <- {:os_auto_update, :update_config_value, update_config_value(:bool, "settings", "os_auto_update", os_auto_update)},
    {:timezone, :type_check, true}                     <- {:timezone, :type_check, (is_binary(tz) or is_nil(tz))},
    {:timezone, :update_config_value, :ok}             <- {:timezone, :update_config_value, update_config_value(:string, "settings", "timezone", tz)},
    {:user_env, :type_check, true}                     <- {:user_env, :type_check, is_map(user_env)},
    {:user_env, :type_cast, {:ok, user_env_enc}}       <- {:user_env, :type_cast, Poison.encode(user_env)},
    {:user_env, :update_config_value, :ok}             <- {:user_env, :update_config_value, update_config_value(:string, "settings", "user_env", user_env_enc)},
    {:first_boot, :update_config_value, :ok}           <- {:first_boot, :update_config_value, update_config_value(:bool, "settings", "first_boot", false)} do
      Logger.success 1, "Configuration data from jsono file was merged."
      :ok
    else
      {step, sub_step, err} ->
        {:error, "#{step} failed at #{sub_step} reason: #{inspect err}"}
    end
  end

  defp migrate_hw(%{"params" => params}) do
    expected_keys = struct(Farmbot.BotState).mcu_params |> Enum.map(fn({key, _}) -> Atom.to_string(key) end)
    migrated = Map.take(params, expected_keys)
    if Enum.all?(migrated, fn({param, val}) ->
      cond do
        is_integer(val) ->
          ConfigStorage.update_config_value(:float, "hardware_params", param, (val / 1))
        is_float(val) ->
          ConfigStorage.update_config_value(:float, "hardware_params", param, val)
        is_nil(val) -> :ok
      end
    end) do
      :ok
    else
      {:error, "Failed to migrate params"}
    end
  end

  defp migrate_network(%{"interfaces" => ifaces}) do
    case do_migrate_network(Map.to_list(ifaces)) do
      [] -> {:error, "No networks were migrated."}
      _ -> :ok
    end
  end

  defp do_migrate_network(ifaces, acc \\ [])

  defp do_migrate_network([], acc), do: acc

  defp do_migrate_network([{ifname, %{"default" => "dhcp", "type" => "wired"}} | rest], acc) do
    %ConfigStorage.NetworkInterface{name: ifname, type: "wired", ipv4_method: "dhcp"}
    |> ConfigStorage.insert()
    |> case do
      {:ok, res} -> do_migrate_network(rest, [res | acc])
      _ -> do_migrate_network(rest, acc)
    end
  end

  defp do_migrate_network([{ifname, %{"default" => "dhcp", "type" => "wireless",
                                      "settings" => %{"key_mgmt" => "WPA-PSK", "psk" => psk, "ssid" => ssid}}} | rest], acc) do
    %ConfigStorage.NetworkInterface{
      name: ifname,
      type: "wireless",
      ssid: ssid,
      psk: psk,
      security: "WPA-PSK",
      ipv4_method: "dhcp" }
    |> ConfigStorage.insert()
    |> case do
      {:ok, res} -> do_migrate_network(rest, [res | acc])
      _ -> do_migrate_network(rest, acc)
    end
  end

  defp do_migrate_network([_ | rest], acc) do
    do_migrate_network(rest, acc)
  end
end
