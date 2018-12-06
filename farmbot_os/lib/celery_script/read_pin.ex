defmodule Farmbot.OS.IOLayer.ReadPin do
  @moduledoc false

  alias Farmbot.Firmware

  def execute(%{pin_number: %{args: %{pin_id: id, pin_type: "Peripheral"}}, pin_mode: m}, body)
      when is_integer(m) do
    case Farmbot.Asset.get_peripheral(id: id) do
      %{pin: p} -> execute(%{pin_number: p, pin_mode: m}, body)
      nil -> {:error, "Could not find peripheral"}
    end
  end

  def execute(%{pin_num: p, pin_mode: m}, body)
      when is_integer(p)
      when is_integer(m) do
    execute(%{pin_number: p, pin_mode: m}, body)
  end

  def execute(%{pin_number: p, pin_mode: m}, _body)
      when is_integer(p)
      when is_integer(m) do
    with {:ok, {_, {:report_pin_value, [p: ^p, v: _]}}} <-
           Firmware.request({:pin_read, p: p, m: m}) do
      :ok
    else
      _ -> {:error, "Firmware Error"}
    end
  end
end
