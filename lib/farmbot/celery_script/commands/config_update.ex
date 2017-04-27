defmodule Farmbot.CeleryScript.Command.ConfigUpdate do
  @moduledoc """
    ConfigUpdate
  """

  alias Farmbot.CeleryScript.Command
  require Logger
  alias Farmbot.Serial.Handler, as: UartHan
  alias Farmbot.Serial.Gcode.Parser, as: GParser
  @behaviour Command
  import Command
  use Farmbot.DebugLog

  @doc ~s"""
    Updates configuration on a package
      args: %{package: String.t},
      body: [Ast.t]
  """
  @spec run(%{package: Command.package}, [Command.pair]) :: no_return
  def run(%{package: "arduino_firmware"}, config_pairs) do
    # check the version to make sure we have a good connection to the firmware
    :ok = check_version()

    blah = pairs_to_tuples(config_pairs)
    current = Farmbot.BotState.get_all_mcu_params

    params = filter_params(blah, current)

    total_count = Enum.count(params)

    debug_log "updating #{inspect params}"
    Enum.reduce(params, 0, fn(pair, count) ->
      do_update_param(pair)
      count = count + 1
      percent = ((count / total_count) * 100)
      percent = trunc(percent)
      if rem(percent, 10) == 0 do
        debug_log "CONFIG UPDATE: #{percent}%"
      end
      count
    end)
  end

  def run(%{package: "farmbot_os"}, config_pairs) do
    blah = pairs_to_tuples(config_pairs)
    for {key, val} <- blah do
      Logger.info ">> Updating #{key}: #{val}"
      Farmbot.BotState.update_config(key, val)
    end
  end

  defp check_version do
    case UartHan.write("F83") do
      {:report_software_version, _version} -> :ok
      e ->
        debug_log "got: #{inspect e}"
        debug_log "Waiting..."
        Process.sleep(2000)
        check_version()
    end
  end

  defp write_and_read(int_and_str, val, tries \\ 0)
  defp write_and_read({_param_int, param_str}, _val, tries) when tries > 5 do
    Logger.info ">> failed to update update: #{param_str}!"
    {:error, :timeout}
  end

  defp write_and_read({param_int, param_str}, val, tries) do
    Logger.info ">> is updating #{param_str}: #{val}"
    case "F22 P#{param_int} V#{val}" |> UartHan.write do
      :timeout -> write_and_read({param_int, param_str}, val, tries + 1)
      _ -> :ok
    end

    # HACK read the param back because sometimes the firmware decides
    # our param sets arent important enough to keep
    case read_param(%{label: param_str}, []) do
      :timeout -> write_and_read({param_int, param_str}, val, tries + 1)
      _ -> :ok
    end
  end

  defp do_update_param({param_str, val}) do
    param_int = GParser.parse_param(param_str)
    if param_int do
      write_and_read({param_int, param_str}, val)
    else
      to_rollbar? = param_str != "nil"
      Logger.error ">> got an unrecognized" <>
        " param: #{inspect param_str}", rollbar: to_rollbar?
    end
  end

  @spec filter_params([{binary, any}], map) :: [{binary, any}]
  defp filter_params(blah, current) do
    result = Enum.filter(blah, fn({param_str, val}) ->
      current[param_str] != val
    end)
    # Im sorry about this
    if Enum.empty?(result), do: blah, else: result
  end

end
