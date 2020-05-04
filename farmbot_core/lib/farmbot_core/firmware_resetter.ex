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
    # TODO: Remove this conditional after we determine
    #       why @gpio is `nil`. -RC 3 MAY 2020
    if @gpio do
      FarmbotCore.Logger.debug(3, "Using special express reset function")
      {:ok, fn -> express_reset_fun() end}
    else
      FarmbotCore.Logger.debug(3, "@gpio unavailable. Using default reset fn.")
      find_reset_fun(nil)
    end
  end

  def find_reset_fun(_) do
    FarmbotCore.Logger.debug(3, "Using default reset function")
    {:ok, fn -> :ok end}
  end

  def express_reset_fun() do
    try do
      gpio_module = @gpio
      FarmbotCore.Logger.debug(3, "Begin MCU reset")
      {:ok, gpio} = gpio_module.open(19, :output)
      :ok         = gpio_module.write(gpio, 0)
      :ok         = gpio_module.write(gpio, 1)
      Process.sleep(1000)
      :ok = gpio_module.write(gpio, 0)
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