defmodule Farmbot.OS.IOLayer.ReadPin do
  @moduledoc false

  alias Farmbot.Firmware

  def execute(%{pin_num: p, pin_mode: m}, _body)
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
