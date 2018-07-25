defmodule Farmbot.BotStateTest do
  use ExUnit.Case, async: false
  alias Farmbot.{BotState, Config}

  test "writing config values goes into state" do
    Config.update_config_value(:bool, "settings", "log_amqp_connected", true)
    assert BotState.fetch().configuration.log_amqp_connected

    Config.update_config_value(:bool, "settings", "log_amqp_connected", false)
    refute BotState.fetch().configuration.log_amqp_connected

  end
end
