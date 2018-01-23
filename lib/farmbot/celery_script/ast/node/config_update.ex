defmodule Farmbot.CeleryScript.AST.Node.ConfigUpdate do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  allow_args [:package]

  def execute(%{package: :farmbot_os}, body, env) do
    env = mutate_env(env)
    do_reduce_os(body, env)
  end

  def execute(%{package: :arduino_firmware}, body, env) do
    env = mutate_env(env)
    do_reduce_fw(body, env)
  end

  defp do_reduce_os([%{args: %{label: key, value: value}} | rest], env) do
    case lookup_os_config(key, value) do
      {:ok, {type, group, value}} ->
        Farmbot.System.ConfigStorage.update_config_value(type, group, key, value)
        Logger.success 3, "Updating: #{inspect key}: #{value}"
        do_reduce_os(rest, env)
      {:error, reason} ->
        {:error, reason, env}
    end
  end

  defp do_reduce_os([], env) do
    {:ok, env}
  end

  defp do_reduce_fw([%{args: %{label: key, value: value}} | rest], env) do
    case Farmbot.Firmware.update_param(:"#{key}", value) do
      :ok -> do_reduce_fw(rest, env)
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_reduce_fw([], env), do: {:ok, env}

  defp lookup_os_config("os_auto_update",            val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}
  defp lookup_os_config("auto_sync",                 val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}
  defp lookup_os_config("timezone",                  val), do: {:ok, {:string, "settings", val}}

  defp lookup_os_config("disable_factory_reset",     val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}

  defp lookup_os_config("sequence_init_log",         val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}
  defp lookup_os_config("sequence_body_log",         val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}
  defp lookup_os_config("sequence_complete_log",     val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}
  defp lookup_os_config("arduino_debug_messages",    val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}
  defp lookup_os_config("firmware_input_log",        val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}
  defp lookup_os_config("firmware_output_log",       val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}
  defp lookup_os_config("beta_opt_in",               val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}
  defp lookup_os_config("email_on_estop",            val), do: {:ok, {:bool,   "settings", format_bool_for_os(val)}}

  defp lookup_os_config("network_not_found_timer",   val) when val > 0, do: {:ok, {:float,  "settings", to_float(val)}}
  defp lookup_os_config("network_not_found_timer",  _val), do: {:error, "network_not_found_timer must be greater than zero"}

  defp lookup_os_config("firmware_hardware", "farmduino"), do: {:ok, {:string, "settings", "farmduino"}}
  defp lookup_os_config("firmware_hardware",   "arduino"), do: {:ok, {:string, "settings", "arduino"}}
  defp lookup_os_config("firmware_hardware",     unknown), do: {:error, "unknown hardware: #{unknown}"}

  defp lookup_os_config(unknown_config,                _), do: {:error, "unknown config: #{unknown_config}"}

  defp format_bool_for_os(1), do: true
  defp format_bool_for_os(0), do: false
  defp format_bool_for_os(true), do: true
  defp format_bool_for_os(false), do: false

  defp to_float(int) when is_integer(int) do
    int / 1
  end

  defp to_float(float) when is_float(float) do
    float
  end
end
