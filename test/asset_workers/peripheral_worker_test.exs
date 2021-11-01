defmodule FarmbotOS.Asset.PeripheralWorkerTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Celery.AST
  alias FarmbotOS.AssetWorker.FarmbotOS.Asset.Peripheral, as: Worker
  alias FarmbotOS.Asset.Peripheral

  setup :verify_on_exit!

  test "peripheral_to_rpc/1" do
    raw = <<154, 60, 54, 238, 159, 53, 21, 160, 176, 202, 22, 177, 28>>
    encoded = "PDwxNTQsIDY"

    peripheral = %Peripheral{
      local_id: raw,
      mode: "output",
      pin: 123
    }

    expect(AST.Factory, :new, 1, fn -> :fake_ast1 end)

    expect(AST.Factory, :rpc_request, 1, fn ast, uuid ->
      assert ast == :fake_ast1
      assert uuid == encoded
      :fake_ast2
    end)

    expect(AST.Factory, :set_pin_io_mode, 1, fn ast, pin, mode ->
      assert mode == "output"
      assert pin == 123
      assert ast == :fake_ast2
      :fake_ast3
    end)

    expect(AST.Factory, :read_pin, 1, fn ast, pin, mode ->
      assert ast == :fake_ast3
      assert pin == 123
      assert mode == "output"
      :fake_ast4
    end)

    assert :fake_ast4 == Worker.peripheral_to_rpc(peripheral)
  end
end
