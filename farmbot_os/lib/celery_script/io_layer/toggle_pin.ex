defmodule Farmbot.OS.IOLayer.TogglePin do
  require Farmbot.Logger

  @digital 0
  @analog 1

  def execute(%{pin_number: num}, []) do
    case Farmbot.Firmware.get_pin_value(num) do
      %{value: 0, mode: @digital} -> high(num)
      %{value: 1, mode: @digital} -> low(num)
      %{value: _, mode: @analog} -> unknown(num)
      nil -> unknown(num)
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  defp unknown(num) do
    Farmbot.Logger.warn 2, "Unknown pin value or analog pin. Writing digital low."
    low(num)
  end

  defp high(num) do
    args = %{pin_mode: @digital, pin_number: num, pin_value: 1}
    jump(args)
  end

  defp low(num) do
    args = %{pin_mode: @digital, pin_number: num, pin_value: 0}
    jump(args)
  end

  defp jump(args), do: Farmbot.OS.IOLayer.write_pin(args, [])
end
