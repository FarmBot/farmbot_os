defmodule FarmbotExt.AMQP.SupportTest do
  @fake_conn %{fake: :connection}

  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotExt.AMQP.Support
  alias FarmbotExt.AMQP.ConnectionWorker
  alias AMQP.{Basic, Channel}

  setup :verify_on_exit!

  test "create_channel" do
    expect(ConnectionWorker, :connection, 1, fn ->
      @fake_conn
    end)

    expect(Channel, :open, 1, fn conn ->
      assert conn == @fake_conn
      {:ok, %{pid: self()}}
    end)

    expect(Basic, :qos, 1, fn chan, opts ->
      assert chan == %{pid: self()}
      assert Keyword.fetch(opts, :global)
      :ok
    end)

    {:ok, {conn, chan}} = Support.create_channel()
    assert conn == @fake_conn
    assert chan == %{pid: self()}
  end

  test "create_channel - error" do
    expect(ConnectionWorker, :connection, 1, fn ->
      :error
    end)

    assert :error == Support.create_channel()
  end
end
