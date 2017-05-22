defmodule Farmbot.CeleryScript.Command.EmergencyLockTest do
  alias Farmbot.CeleryScript.{Command, Ast}
  use Farmbot.Test.Helpers.SerialTemplate, async: false

  describe "emergency_lock" do
    test "wont lock the bot if its already locked", %{cs_context: context} do
      # actually lock the bot
      ast = good_ast()
      Command.do_command(ast, context)

      serial_state = :sys.get_state(context.serial)
      assert serial_state.status == :locked

      config_state = :sys.get_state(context.configuration)

      assert config_state.informational_settings.sync_status == :locked
      assert config_state.informational_settings.locked == true

      assert_raise RuntimeError, "Bot is already locked", fn() ->
        Command.do_command(ast, context)
      end
    end
  end

  defp good_ast, do: %Ast{kind: "emergency_lock", args: %{}, body: []}
end
