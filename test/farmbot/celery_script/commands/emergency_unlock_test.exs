defmodule Farmbot.CeleryScript.Command.EmergencyUnLockTest do
  alias Farmbot.CeleryScript.{Command, Ast}
  use Farmbot.Test.Helpers.SerialTemplate, async: false

  describe "emergency_unlock" do
    test "ensures serial", %{cs_context: context} do
      assert Farmbot.Serial.Handler.available?(context)
    end

    test "wont lock the bot if its already locked", %{cs_context: context} do
      # actually lock the bot
      lock_ast = good_lock_ast()
      Command.do_command(lock_ast, context)

      serial_state = :sys.get_state(context.serial)
      assert serial_state.status == :locked

      config_state = :sys.get_state(context.configuration)

      assert config_state.informational_settings.sync_status == :locked
      assert config_state.informational_settings.locked == true

      unlock_ast = good_unlock_ast()
      Command.do_command(unlock_ast, context)

      serial_state = :sys.get_state(context.serial)
      assert serial_state.status == :locked

      config_state = :sys.get_state(context.configuration)

      assert config_state.informational_settings.sync_status == :locked
      assert config_state.informational_settings.locked == true

      assert_raise RuntimeError, "Bot is already locked", fn() ->
        Command.do_command(unlock_ast, context)
      end
    end
  end

  defp good_lock_ast, do: %Ast{kind: "emergency_lock", args: %{}, body: []}
  defp good_unlock_ast, do: %Ast{kind: "emergency_unlock", args: %{}, body: []}
end
