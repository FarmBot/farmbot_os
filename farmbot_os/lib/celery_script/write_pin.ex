defmodule Farmbot.OS.IOLayer.WritePin do
  @moduledoc false

  alias Farmbot.Firmware

  def execute(
        %{pin_number: %{args: %{pin_id: id, pin_type: "Peripheral"}}, pin_mode: m, pin_value: v},
        body
      )
      when is_integer(m)
      when is_integer(v) do
    case Farmbot.Asset.get_peripheral(id: id) do
      %{pin: p} -> execute(%{pin_number: p, pin_mode: m, pin_value: v}, body)
      nil -> {:error, "Could not find peripheral"}
    end
  end

  def execute(%{pin_number: p, pin_mode: m, pin_value: v}, _body) when is_integer(p) do
    with :ok <- Firmware.command({:pin_write, [p: p, m: m, v: v]}),
         {:ok, {_, {:report_pin_value, [p: ^p, v: ^v]}}} <-
           Firmware.request({:pin_read, p: p, m: m}) do
      :ok
    else
      _ -> {:error, "Firmware Error"}
    end
  end
end
