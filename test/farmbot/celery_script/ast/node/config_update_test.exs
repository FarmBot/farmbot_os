defmodule Farmbot.CeleryScript.AST.Node.ConfigUpdateTest do
  alias Farmbot.CeleryScript.AST.Node.{ConfigUpdate, Pair}

  use FarmbotTestSupport.AST.NodeTestCase, async: false
  alias Farmbot.System.ConfigStorage

  test "mutates env", %{env: env} do
    {:ok, env} = ConfigUpdate.execute(%{package: :farmbot_os}, [], env)
    assert_cs_env_mutation(ConfigUpdate, env)
  end

  test "sets network_not_found_timer", %{env: env} do
    ConfigUpdate.execute(%{package: :farmbot_os}, pair("network_not_found_timer", 1000), env)
    |> assert_cs_success()

    assert ConfigStorage.get_config_value(:float, "settings", "network_not_found_timer") == 1000.0
  end

  test "Wont set network_not_found_timer to a negative number", %{env: env} do
    old = ConfigStorage.get_config_value(:float, "settings", "network_not_found_timer")
    ConfigUpdate.execute(%{package: :farmbot_os}, pair("network_not_found_timer", -1), env)
    |> assert_cs_fail("network_not_found_timer must be greater than zero")

    assert ConfigStorage.get_config_value(:float, "settings", "network_not_found_timer") == old
  end

  test "sets os auto update", %{env: env} do
    ConfigUpdate.execute(%{package: :farmbot_os}, pair("os_auto_update", true), env) |> assert_cs_success()
    assert ConfigStorage.get_config_value(:bool, "settings", "os_auto_update")

    ConfigUpdate.execute(%{package: :farmbot_os}, pair("os_auto_update", false), env) |> assert_cs_success()
    refute ConfigStorage.get_config_value(:bool, "settings", "os_auto_update")
  end

  test "sets auto sync", %{env: env} do
    ConfigUpdate.execute(%{package: :farmbot_os}, pair("auto_sync", true), env) |> assert_cs_success()
    assert ConfigStorage.get_config_value(:bool, "settings", "auto_sync")

    ConfigUpdate.execute(%{package: :farmbot_os}, pair("auto_sync", false), env) |> assert_cs_success()
    refute ConfigStorage.get_config_value(:bool, "settings", "auto_sync")
  end

  test "can not set arduino hardware to unknown setting", %{env: env} do
    ConfigUpdate.execute(%{package: :farmbot_os}, pair("firmware_hardware", "whoops"), env)
    |> assert_cs_fail("unknown hardware: whoops")

    refute ConfigStorage.get_config_value(:string, "settings", "firmware_hardware") == "whoops"
  end

  test "gives decent error on unknown onfig files.", %{env: env} do
    ConfigUpdate.execute(%{package: :farmbot_os}, pair("some_other_config", "whoops"), env)
    |> assert_cs_fail("unknown config: some_other_config")
  end

  test "can set float values with an integer", %{env: env} do
    ConfigUpdate.execute(%{package: :farmbot_os}, pair("network_not_found_timer", 1000), env)
    |> assert_cs_success()
  end

  test "can set float values with a float", %{env: env} do
    ConfigUpdate.execute(%{package: :farmbot_os}, pair("network_not_found_timer", 1000.00), env)
    |> assert_cs_success()
  end

  test "allows setting multiple configs", %{env: env} do
    pairs = pairs([{"network_not_found_timer", 10.0}, {"firmware_hardware", "farmduino"}])
    ConfigUpdate.execute(%{package: :farmbot_os}, pairs, env) |> assert_cs_success()

    assert ConfigStorage.get_config_value(:string, "settings", "firmware_hardware") == "farmduino"
    assert ConfigStorage.get_config_value(:float, "settings", "network_not_found_timer") == 10.0
  end

  defp pair(key, val) do
    {:ok, pair, _} = Pair.execute(%{label: key, value: val}, [], struct(Macro.Env, []))
    [pair]
  end

  defp pairs(pairs) do
    Enum.map(pairs, fn({key, val}) -> pair(key, val) end) |> List.flatten()
  end
end
