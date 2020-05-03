defmodule FarmbotCore.FirmwareResetter do
  defmodule Stub do
    require FarmbotCore.Logger

    def fail do
      m = "Reset function NOT FOUND. Please notify FarmBot support."
      FarmbotCore.Logger.error(3, m)
      {:error, m}
    end

    def open(_, _), do: fail()
    def write(_, _), do: fail()
  end

  @gpio Application.get_env(:farmbot_core, __MODULE__, [])[:gpio] || Stub
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
      FarmbotCore.Logger.debug(3, "Begin MCU reset")
      {:ok, gpio} = @gpio.open(19, :output)
      :ok = @gpio.write(gpio, 0)
      :ok = @gpio.write(gpio, 1)
      Process.sleep(1000)
      :ok = @gpio.write(gpio, 0)
      FarmbotCore.Logger.debug(3, "Finish MCU Reset")
      :ok
    rescue
      ex ->
        message = Exception.message(ex)
        msg = "Could not reset express firmware: #{message}"
        FarmbotCore.Logger.error(3, msg)
        :express_reset_error
    end
  end
end