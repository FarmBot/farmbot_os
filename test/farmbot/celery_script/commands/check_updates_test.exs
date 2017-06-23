defmodule Farmbot.CeleryScript.Command.CheckUpdatesTest do
  use ExUnit.Case, async: true
  alias Farmbot.CeleryScript.{Ast, Command, Error}
  import Mock

  test "doesnt check for arduino updates anymore" do
    ctx = Farmbot.Context.new()
    ast = %Ast{kind: "check_updates", args: %{package: "arduino_firmware"}, body: []}
    assert_raise Error, "arduino firmware is now bundled into the OS.", fn() ->
      Command.do_command(ast, ctx)
    end
  end

  test "doesnt know what to do with other strings" do
    ctx = Farmbot.Context.new()
    ast = %Ast{kind: "check_updates", args: %{package: "explorer.exe"}, body: []}
    assert_raise Error, "unknown package: #{ast.args.package}", fn() ->
      Command.do_command(ast, ctx)
    end
  end

  test "does update check for fbos" do
    # the real update thing will be checked elsewhere, this is just for the ast node.
    with_mock Farmbot.System.Updates, [check_and_download_updates: fn(_) -> :ok end] do
      ctx = Farmbot.Context.new()
      ast = %Ast{kind: "check_updates", args: %{package: "farmbot_os"}, body: []}
      Command.do_command(ast, ctx)
      assert called Farmbot.System.Updates.check_and_download_updates(ctx)
    end
  end
end
