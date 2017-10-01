defmodule Farmbot.Firmware do
  @moduledoc "Allows communication with the firmware."

  use GenStage
  require Logger

  @handler Application.get_env(:farmbot, :behaviour)[:firmware_handler] || raise "No fw handler."

  @doc "Start the firmware services."
  def start_link(opts) do
    GenStage.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:producer_consumer, [], subscribe_to: [@handler]}
  end

  def handle_events(gcodes, _from, state) do
    {:noreply, handle_gcodes(gcodes), state}
  end

  def handle_gcodes(codes, acc \\ [])
  def handle_gcodes([], acc), do: Enum.reverse(acc)
  def handle_gcodes([code | rest], acc) do
    res = handle_gcode(code)
    if res do
      handle_gcodes(rest, [res | acc])
    else
      handle_gcodes(rest, acc)
    end
  end

  def handle_gcode({:report_current_position, x, y, z}) do
    {:location_data, %{position: %{x: x, y: y, z: z}}}
  end

  def handle_gcode(_code) do
    # Logger.warn "unhandled code: #{inspect code}"
    nil
  end
end
