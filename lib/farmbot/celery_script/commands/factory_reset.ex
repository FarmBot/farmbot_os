defmodule Farmbot.CeleryScript.Command.FactoryReset do
  @moduledoc """
    FactoryReset
  """

  # alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.{Command, Ast}
  require Logger
  @behaviour Command
  import Command

  @doc ~s"""
    Factory resets bot.
      args: %{package: "farmbot_os" | "arduino_firmware"}
      body: []
  """
  @spec run(%{package: binary}, [], Ast.context) :: Ast.context
  def run(%{package: "farmbot_os"}, [], context) do
    Logger.info(">> Going down for factory reset in 5 seconds!", type: :warn)
    spawn fn ->
      Process.sleep 5000
      do_fac_reset_fw(context)
      Farmbot.System.factory_reset("I was asked by a CeleryScript command.")
    end
    context
  end

  def run(%{package: "arduino_firmware"}, [], context) do
    do_fac_reset_fw(context)
    context
  end

  @spec do_fac_reset_fw(Ast.context, boolean) :: no_return
  defp do_fac_reset_fw(context, reboot \\ false) do
    Logger.info(">> Going to reset my arduino!", type: :warn)
    params =
      Farmbot.BotState.get_all_mcu_params()
      |> Enum.map(fn({key, _value}) ->
        if key do
          key
          |> String.to_existing_atom()
          |> Farmbot.BotState.set_param(-1)
        end
        pair(%{label: key, value: -1}, [], context)
      end)
    config_update(%{package: "arduino_firmware"}, params, context)

    file = "#{Farmbot.System.FS.path()}/config.json"
    config_file = file |> File.read!() |> Poison.decode!()
    f = %{config_file | "hardware" => %{config_file["hardware"] | "params" => %{}}}
    Farmbot.System.FS.transaction fn() ->
      File.write file, Poison.encode!(f)
    end, true
    GenServer.stop(Farmbot.Serial.Handler, :reset)
    if reboot, do: Farmbot.System.reboot()
  end

end
