defmodule FarmbotTelemetryTest do
  use ExUnit.Case
  doctest FarmbotTelemetry
  use FarmbotTelemetry

  defmodule TestHandler do
    def handle_event([class, type], %{action: action}, meta, config) do
      send(config[:test_pid], {class, type, action, meta, config})
    end
  end

  describe "network" do
    setup do
      opts = [
        class: NetworkClass,
        handler_id: "#{inspect(self())}",
        handler: &TestHandler.handle_event/4,
        config: [test_pid: self()]
      ]

      :ignore = FarmbotTelemetry.attach(opts)
      :ok
    end

    test "access_point.disconnect" do
      FarmbotTelemetry.execute(NetworkClass, :access_point, :disconnect, %{ssid: "test"})
      assert_receive {NetworkClass, :access_point, :disconnect, %{ssid: "test"}, _}
    end

    test "access_point.connect" do
      FarmbotTelemetry.execute(NetworkClass, :access_point, :connect, %{ssid: "test"})
      assert_receive {NetworkClass, :access_point, :connect, %{ssid: "test"}, _}
    end

    test "access_point.eap_error" do
      FarmbotTelemetry.execute(NetworkClass, :access_point, :eap_error, %{ssid: "test"})
      assert_receive {NetworkClass, :access_point, :eap_error, %{ssid: "test"}, _}
    end

    test "access_point.assosiate_error" do
      FarmbotTelemetry.execute(NetworkClass, :access_point, :assosiate_error, %{ssid: "test"})
      assert_receive {NetworkClass, :access_point, :assosiate_error, %{ssid: "test"}, _}
    end

    test "access_point.assosiate_timeout" do
      FarmbotTelemetry.execute(NetworkClass, :access_point, :assosiate_timeout, %{ssid: "test"})
      assert_receive {NetworkClass, :access_point, :assosiate_timeout, %{ssid: "test"}, _}
    end
  end
end
