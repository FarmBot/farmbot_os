defmodule Farmbot.FirmwareTest do
  @moduledoc "Tests the Firmware transport."
  use ExUnit.Case

  alias Farmbot.Firmware

  defmodule FirmwareHandler do
    use GenServer

    def start_link(firmware, opts) do
      GenServer.start_link(__MODULE__, firmware, opts)
    end
  end

  setup do
    bss = Farmbot.BotStateSupport.start_bot_state_stack()
    mod = FirmwareHandler

    {:ok, firmware} =
      Firmware.start_link(
        bss.bot_state,
        bss.informational_settings,
        bss.configuration,
        bss.location_data,
        bss.mcu_params,
        mod,
        []
      )

    {:ok, Map.put(bss, :firmware, firmware)}
  end

  test "gives an error on unknown/unimmplemented gcode", ctx do
    r = Firmware.handle_gcode(ctx.firmware, {:not_real, 1})
    assert r == {:error, :unhandled}
  end

  test "sets busy to false on idle", ctx do
    Firmware.handle_gcode(ctx.firmware, :idle)
    assert :sys.get_state(ctx.bot_state).bot_state.informational_settings.busy == false
  end

  test "reports position", ctx do
    Firmware.handle_gcode(ctx.firmware, {:report_current_position, 123, 1234, -123})

    assert match?(
             %{x: 123, y: 1234, z: -123},
             :sys.get_state(ctx.bot_state).bot_state.location_data.position
           )
  end

  test "reports scaled encoders", ctx do
    Firmware.handle_gcode(ctx.firmware, {:report_encoder_position_scaled, 123, 1234, -123})

    assert match?(
             %{x: 123, y: 1234, z: -123},
             :sys.get_state(ctx.bot_state).bot_state.location_data.scaled_encoders
           )
  end

  test "reports raw encoders", ctx do
    Firmware.handle_gcode(ctx.firmware, {:report_encoder_position_raw, 123, 1234, -123})

    assert match?(
             %{x: 123, y: 1234, z: -123},
             :sys.get_state(ctx.bot_state).bot_state.location_data.raw_encoders
           )
  end

  test "reports end stops", ctx do
    Firmware.handle_gcode(ctx.firmware, {:report_end_stops, 1, 1, 0, 0, 1, 1})
    assert :sys.get_state(ctx.bot_state).bot_state.location_data.end_stops == "110011"
  end
end
