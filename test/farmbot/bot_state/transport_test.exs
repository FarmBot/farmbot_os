defmodule Farmbot.BotState.TransportTest do
  @moduledoc "Tests BotState Transport"

  alias Farmbot.BotState.Transport
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.Log

  use ExUnit.Case

  defmodule StubTransport do
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end

    def emit(_msg) do
      :ok
    end

    def log(_msg) do
      :ok
    end

  end

  setup_all do
    {:ok, _tp} = StubTransport.start_link
    old = Application.get_env(:farmbot, :transport)
    new = old ++ [StubTransport]
    Application.put_env(:farmbot, :transport, new)
  end

  test "emits an ast" do
    msg = %Ast{kind: "hello", args: %{}, body: []}
    resp = Transport.emit(msg)
    Enum.map(resp, fn(res) -> assert res == :ok end)
  end

  test "logs a message" do
    log = %Log{
      meta: [],
      message: "hello",
      created_at: DateTime.utc_now(),
      channels: []
    }
    resp = Transport.log(log)
    Enum.map(resp, fn(res) -> assert res == :ok end)
  end

end
