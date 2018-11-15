defmodule Farmbot.OS.IOLayer.TogglePin do
  @moduledoc false

  alias Farmbot.Firmware
  @mode_digital 0

  def execute(%{pin_number: num}, _body) when is_integer(num) do
    case Firmware.request({:pin_read, p: num, m: @mode_digital}) do
      {:ok, {_, {:report_pin_value, [p: ^num, v: v]}}} -> do_toggle(num, v)
      {:error, _} -> {:error, "Firmware Error"}
    end
  end

  def do_toggle(num, 0) when is_integer(num) do
    command(num, 1)
  end

  def do_toggle(num, _) when is_integer(num) do
    command(num, 0)
  end

  def command(num, val) when is_integer(num) do
    with :ok <- Firmware.command({:pin_write, [p: num, m: @mode_digital, v: val]}),
         {:ok, {_, {:report_pin_value, [p: ^num, v: ^val]}}} <-
           Firmware.request({:pin_read, p: num, m: @mode_digital}) do
      :ok
    else
      _ -> {:error, "Ffirmware Error"}
    end
  end
end
