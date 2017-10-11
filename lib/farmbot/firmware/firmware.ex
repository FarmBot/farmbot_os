defmodule Farmbot.Firmware do
  @moduledoc "Allows communication with the firmware."

  use GenStage
  require Logger

  defmodule Handler do
    @moduledoc """
    Any module that implements this behaviour should be a GenStage.

    The implementng stage should communicate with the various Farmbot
    hardware such as motors and encoders. The `Farmbot.Firmware` module
    will subscribe_to: the implementing handler. Events should be
    Gcodes as parsed by `Farmbot.Firmware.Gcode.Parser`.
    """

    @doc "Start a firmware handler."
    @callback start_link :: GenServer.on_start()

    @doc "Write a gcode."
    @callback write(Farmbot.Firmware.Gcode.t()) :: :ok | {:error, term}
  end

  @handler Application.get_env(:farmbot, :behaviour)[:firmware_handler] || raise("No fw handler.")

  @doc "Start the firmware services."
  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Writes a Gcode to a the running hand:ler"
  def write(code), do: @handler.write(code)

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

  def handle_gcode(code) do
    Logger.warn("unhandled code: #{inspect(code)}")
    nil
  end
end
