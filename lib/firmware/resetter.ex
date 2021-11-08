defmodule FarmbotOS.Firmware.Resetter do
  alias FarmbotOS.Asset
  require FarmbotOS.Logger

  if Code.ensure_compiled(Circuits.GPIO) do
    @gpio Circuits.GPIO
  else
    @gpio nil
  end

  def reset(package \\ nil) do
    pkg = package || Asset.fbos_config(:firmware_hardware)
    {:ok, fun} = find_reset_fun(pkg)
    fun.()
  end

  def find_reset_fun("express_k10"), do: use_special_fn(@gpio)
  def find_reset_fun(_), do: use_default()

  defp use_special_fn(nil), do: use_default()

  defp use_special_fn(_) do
    msg = "Using special express reset function"
    FarmbotOS.Logger.debug(3, msg)
    {:ok, fn -> run_special_reset(@gpio) end}
  end

  def use_default(), do: {:ok, fn -> :ok end}

  def run_special_reset(gpio_module) do
    FarmbotOS.Logger.debug(3, "Begin MCU reset")
    {:ok, gpio} = gpio_module.open(19, :output)
    :ok = gpio_module.write(gpio, 0)
    :ok = gpio_module.write(gpio, 1)
    Process.sleep(1100)
    :ok = gpio_module.write(gpio, 0)
    gpio_module.close(gpio)
    FarmbotOS.Logger.debug(3, "Finish MCU Reset")
    :ok
  end
end
