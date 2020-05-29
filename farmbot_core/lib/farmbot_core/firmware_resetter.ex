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
    {:ok, fn -> express_reset_fun() end}
  end

  def find_reset_fun(_) do
    FarmbotCore.Logger.debug(3, "Using default reset function")
    {:ok, fn -> :ok end}
  end

  def express_reset_fun() do
    try do
      gpio_module = @gpio
      # 800..1200 in 50ms increments
      time = Enum.random(16..24) * 50
      a = Enum.random(0..1)
      b = Enum.random(0..1)
      c = Enum.random(0..1)
      FarmbotCore.Logger.debug(3, "Begin MCU reset (#{time}ms => #{a} #{b} #{c})")
      {:ok, gpio} = gpio_module.open(19, :output)
      :ok         = gpio_module.write(gpio, a)
      :ok         = gpio_module.write(gpio, b)
      Process.sleep(time)
      :ok = gpio_module.write(gpio, c)
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