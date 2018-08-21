defmodule Farmbot.Asset.Settings.FbosConfig do
  @moduledoc false
  import Farmbot.Asset.Settings.Helpers
  require Farmbot.Logger
  @keys ~W(arduino_debug_messages
           auto_sync
           beta_opt_in
           disable_factory_reset
           firmware_hardware
           firmware_input_log
           firmware_output_log
           network_not_found_timer
           os_auto_update
           sequence_body_log
           sequence_complete_log
           sequence_init_log)

  def download(new, old) do
    new = Map.take(new, @keys)
    for k <- @keys do
      if old[k] != new[k] do
        try do
          apply_kv(k, new[k], old[k])
        rescue
          _ -> Farmbot.Logger.error 1, "Failed to apply Fbos Config: #{k}"
        end
      end
    end
    :ok
  end

  def log(key, new, old) do
    Farmbot.Logger.info 3, "Fbos Config #{key} updated: #{new || "NULL"} => #{old || "NULL"}"
  end

  bool("arduino_debug_messages")
  bool("auto_sync")
  bool("beta_opt_in")
  bool("disable_factory_reset")
  bool("firmware_input_log")
  bool("firmware_output_log")
  bool("os_auto_update")
  bool("sequence_body_log")
  bool("sequence_complete_log")
  bool("sequence_init_log")

  string("firmware_hardware")
  float("network_not_found_timer")
end
