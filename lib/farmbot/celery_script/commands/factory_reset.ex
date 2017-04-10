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
    Logger.warn(">> Going down for factory reset in 5 seconds!")
    spawn fn ->
      Process.sleep 5000
      # do_fac_reset_fw()
      Farmbot.System.factory_reset()
    end
  end

  def run(%{package: "arduino_firmware"}, []) do
    do_fac_reset_fw(true)
  end

  # TODO(Connor): Delete this part
  def run(%{}, []), do: factory_reset(%{package: "farmbot_os"}, [])

  @spec do_fac_reset_fw(boolean) :: no_return
  defp do_fac_reset_fw(reboot \\ false) do
    Logger.warn(">> Going to reset my arduino!")
    params =
      Farmbot.BotState.get_all_mcu_params()
      |> Enum.map(fn({key, _value}) ->
        pair(%{label: key, value: -1}, [])
      end)

    config_update(%{package: "arduino_firmware"}, params)

    if reboot, do: Farmbot.System.reboot()
  end

end
