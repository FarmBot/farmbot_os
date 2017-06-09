defmodule Farmbot.CeleryScript.Command.FactoryReset do
  @moduledoc """
    FactoryReset
  """

  alias      Farmbot.CeleryScript.{Command}
  alias      Farmbot.Context
  require    Logger
  @behaviour Command
  import     Command

  @doc ~s"""
    Factory resets bot.
      args: %{package: "farmbot_os" | "arduino_firmware"}
      body: []
  """
  @spec run(%{package: binary}, [], Context.t) :: Context.t
  def run(%{package: "farmbot_os"}, [], context) do
    Logger.info(">> Going down for factory reset in 5 seconds!", type: :warn)
    spawn fn ->
      Farmbot.BotState.set_sync_msg(context, :maintenance)
      Process.sleep 5000
      # do_fac_reset_fw(context)
      Farmbot.System.factory_reset("I was asked by a CeleryScript command.")
    end
    context
  end

  def run(%{package: "arduino_firmware"}, [], context) do
    do_fac_reset_fw(context)
    context
  end

  @spec do_fac_reset_fw(Context.t, boolean) :: no_return
  defp do_fac_reset_fw(context, reboot \\ false) do
    Logger.info(">> Going to reset my arduino!", type: :warn)
    Farmbot.BotState.set_sync_msg(context, :maintenance)
    params_map           = Farmbot.BotState.get_all_mcu_params(context)
    context1             = to_pairs(Map.to_list(params_map), context)
    {params, context2}   = get_params(Enum.count(params_map), context1)

    context3   = config_update(%{package: "arduino_firmware"}, params, context2)

    file = "#{Farmbot.System.FS.path()}/config.json"
    config_file = file |> File.read!() |> Poison.decode!()
    f = %{config_file | "hardware" => %{config_file["hardware"] | "params" => %{}}}

    Farmbot.System.FS.transaction fn() ->
      File.write file, Poison.encode!(f)
    end, true

    GenServer.stop(context3.serial, :reset)

    if reboot do
      Farmbot.System.reboot()
    else
      Farmbot.BotState.set_sync_msg(context3, :sync_now)
      context3
    end
  end

  @spec to_pairs([{atom, binary}], Context.t) :: Context.t
  defp to_pairs(params_list, context_accumulator)
  defp to_pairs([], %Context{} = acc), do: acc
  defp to_pairs([{key, _value} | rest], %Context{} = acc) do
    # have some side effects.
    if key do
      param = String.to_atom(key)
      Farmbot.BotState.set_param(acc, param, -1)
      to_pairs(rest, pair(%{label: key, value: -1}, [], acc))
    else
      acc
    end
  end

  defp get_params(count, context, acc \\ [])

  defp get_params(0, %Context{} = context, params) do
    {params, context}
  end

  defp get_params(count, %Context{data_stack: [param | rest]} = ctx, acc) do
    get_params(count - 1, %{ctx | data_stack: rest}, [param | acc])
  end
end
