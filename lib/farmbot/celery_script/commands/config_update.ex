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

  @doc ~s"""
    Updates configuration on a package
      args: %{package: String.t},
      body: [Ast.t]
  """
  @lint false
  @spec run(%{package: Command.package}, [Command.pair]) :: no_return
  def run(%{package: "arduino_firmware"}, config_pairs) do
    # check the version to make sure we have a good connection to the firmware
    :ok = check_version()

    blah = pairs_to_tuples(config_pairs)
    current = Farmbot.BotState.get_all_mcu_params

    params = filter_params(blah, current)

    total_count = Enum.count(params)

    IO.puts "updating #{inspect params}"
    Enum.reduce(params, 0, fn(pair, count) ->
      do_update_param(pair)
      count = count + 1
      percent = ((count / total_count) * 100) |> trunc
      if rem(percent, 10) == 0 do
        IO.puts "CONFIG UPDATE: #{percent}%"
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
        IO.puts "got: #{inspect e}"
        IO.puts "Waiting..."
        Process.sleep(2000)
        check_version()
    end
  end

  defp do_update_param({param_str, val}) do
    param_int = GParser.parse_param(param_str)
    if param_int do
      Logger.info ">> is updating #{param_str}: #{val}"
      "F22 P#{param_int} V#{val}" |> UartHan.write
      # HACK read the param back because sometimes the firmware decides
      # our param sets arent important enough to keep
      read_param(%{label: param_str}, [])
    else
      Logger.error ">> got an unrecognized param: #{param_str}"
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
#C.config_update %{package: "arduino_firmware"}, [pair, pair2]
