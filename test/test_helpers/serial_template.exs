defmodule Farmbot.Test.Helpers.SerialTemplate do
  alias Farmbot.Serial.Handler
  alias Farmbot.Test.SerialHelper
  use ExUnit.CaseTemplate

  defp wait_for_serial(context) do
    unless Handler.available?(context) do
      # IO.puts "waiting for serial..."
      Process.sleep(100)
      wait_for_serial(context)
    end
  end

  setup_all do
    {{hand, firm}, slot, context} = SerialHelper.setup_serial()
    wait_for_serial(context)

     on_exit fn() -> SerialHelper.teardown_serial({hand, firm}, slot) end
     [cs_context: context, serial_handler: hand, firmware_sim: firm]
  end
end
