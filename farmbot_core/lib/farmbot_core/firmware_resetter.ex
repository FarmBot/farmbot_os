defmodule FarmbotCore.FirmwareResetter do
  if Code.ensure_compiled?(Circuits.GPIO) do
    @gpio Circuits.GPIO
  else
    @gpio nil
  end
  alias FarmbotCore.Asset
  require FarmbotCore.Logger

  def reset(package \\ nil) do
    pkg = package || Asset.fbos_config(:firmware_hardware)
    FarmbotCore.Logger.debug(3, "Attempting to retrieve #{pkg} reset function.")
    {:ok, fun} = find_reset_fun(pkg)
    fun.()
  end

  def find_reset_fun("express_k10") do
    FarmbotCore.Logger.debug(3, "Using special express reset function")
    {:ok, fn -> express_reset_fun(@gpio) end}
  end

  def find_reset_fun(_) do
    FarmbotCore.Logger.debug(3, "Using default reset function")
    {:ok, fn -> :ok end}
  end

  defp express_reset_fun(nil) do
    FarmbotCore.Logger.debug(3, "GPIO module not found; Skipping firmware reset.")
  end

  defp express_reset_fun(gpio_module) do
    try do
      FarmbotCore.Logger.debug(3, "Begin MCU reset")
      {:ok, gpio} = gpio_module.open(19, :output)
      :ok         = gpio_module.write(gpio, 0)
      :ok         = gpio_module.write(gpio, 1)
      Process.sleep(1100)
      :ok = gpio_module.write(gpio, 0)
      gpio_module.close(gpio)
      FarmbotCore.Logger.debug(3, "Finish MCU Reset")
      :ok
    rescue
      ex ->
        message = Exception.message(ex)
        msg = "Express reset failed #{message}"
        FarmbotCore.Logger.error(3, msg)
        {:error, msg}
    end
  end
end