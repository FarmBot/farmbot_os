defmodule Farmbot.CeleryScript.Command.FactoryReset do
  @moduledoc """
    FactoryReset
  """

  # alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command
  import Command

  @doc ~s"""
    Factory resets bot.
      args: %{package: "farmbot_os" | "arduino_firmware"}
      body: []
  """
  @spec run(%{package: binary}, []) :: no_return
  def run(%{package: "farmbot_os"}, []) do
    Logger.info(">> Going down for factory reset in 5 seconds!", type: :warn)
    spawn fn ->
      Process.sleep 5000
      do_fac_reset_fw()
      Farmbot.System.factory_reset()
    end
  end

  def run(%{package: "arduino_firmware"}, []) do
    do_fac_reset_fw(true)
  end

  @spec do_fac_reset_fw(boolean) :: no_return
  defp do_fac_reset_fw(reboot \\ false) do
    Logger.info(">> Going to reset my arduino!", type: :warn)
    params =
      Farmbot.BotState.get_all_mcu_params()
      |> Enum.map(fn({key, _value}) ->
        if key do
          key
          |> String.to_existing_atom()
          |> Farmbot.BotState.set_param(-1)
        end
        pair(%{label: key, value: -1}, [])
      end)
    config_update(%{package: "arduino_firmware"}, params)

    file = "#{Farmbot.System.FS.path()}/config.json"
    config_file = file |> File.read!() |> Poison.decode!()
    f = %{config_file | "hardware" => %{config_file["hardware"] | "params" => %{}}}
    Farmbot.System.FS.transaction fn() ->
      File.write file, Poison.encode!(f)
    end

    if reboot, do: Farmbot.System.reboot()
  end

end
