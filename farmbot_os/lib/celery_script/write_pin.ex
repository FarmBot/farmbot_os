defmodule Farmbot.OS.IOLayer.WritePin do
  @moduledoc false

  alias Farmbot.Firmware

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
