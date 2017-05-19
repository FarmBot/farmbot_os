defmodule Farmbot.CeleryScript.Command.ConfigUpdate do
  @moduledoc """
    ConfigUpdate
  """

  alias Farmbot.CeleryScript.Command
  require Logger
  alias Farmbot.Serial.Handler, as: UartHan
  alias Farmbot.Serial.Gcode.Parser, as: GParser
  @behaviour Command
  import Command, only: [read_param: 3, pairs_to_tuples: 1]
  use Farmbot.DebugLog

  @doc ~s"""
    Updates configuration on a package
      args: %{package: String.t},
      body: [Ast.t]
  """
  @spec run(%{package: Command.package},
            [Command.pair],
            Ast.context) :: Ast.context
  def run(%{package: "arduino_firmware"}, config_pairs, context) do
    # check the version to make sure we have a good connection to the firmware
    :ok = check_version(context)

    blah = pairs_to_tuples(config_pairs)
    current = Farmbot.BotState.get_all_mcu_params(context)

    params = filter_params(blah, current)

    total_count = Enum.count(params)

    debug_log "updating #{inspect params}"
    count =
      Enum.reduce(params, 0, fn(pair, count) ->
        do_update_param(context, pair)
        count = count + 1
        percent = ((count / total_count) * 100)
        percent = trunc(percent)
        if rem(percent, 10) == 0 do
          debug_log "CONFIG UPDATE: #{percent}%"
        end
        count
      end)

    if count > 5 do
      UartHan.write(context, "F20")
    else
      for {param_str, _val} <- params do
        read_param(%{label: param_str}, [], context)
      end
    end
    context
  end

  def run(%{package: "farmbot_os"}, config_pairs, context) do
    blah = pairs_to_tuples(config_pairs)
    for {key, val} <- blah do
      Logger.info ">> Updating #{key}: #{val}"
      Farmbot.BotState.update_config(context, key, val)
    end
    context
  end

  defp check_version(context) do
    case UartHan.write(context, "F83") do
      {:report_software_version, _version} -> :ok
      nil -> :ok # FIXME!!
      e ->
        debug_log "got: #{inspect e}"
        debug_log "Waiting..."
        Process.sleep(2000)
        check_version(context)
    end
  end

  defp write_and_read(_context, int_and_str, val, tries \\ 0)
  defp write_and_read(_context, {_param_int, param_str}, _val, tries)
  when tries > 5 do
    Logger.info ">> failed to update update: #{param_str}!"
    {:error, :timeout}
  end

  defp write_and_read(context, {param_int, param_str}, val, tries) do
    Logger.info ">> is updating #{param_str}: #{val}"
    gcode = "F22 P#{param_int} V#{val}"
    results = UartHan.write(context, gcode)
    case results do
      :timeout ->
        write_and_read(context, {param_int, param_str}, val, tries + 1)
      _ -> :ok
    end

    # # HACK read the param back because sometimes the firmware decides
    # # our param sets arent important enough to keep
    # case read_param(%{label: param_str}, []) do
    #   :timeout -> write_and_read({param_int, param_str}, val, tries + 1)
    #   _ -> :ok
    # end
  end

  defp do_update_param(context, {param_str, val}) do
    param_int = GParser.parse_param(param_str)
    if param_int do
      r = write_and_read(context, {param_int, param_str}, val)
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
