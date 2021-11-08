defmodule FarmbotOS.Bootstrap.DropPasswordSupportTest do
  require Helpers

  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.Config

  test "set_secret(secret)" do
    fake_secret = "shhh..."
    FarmbotOS.Bootstrap.DropPasswordSupport.set_secret(fake_secret)
    secret = Config.get_config_value(:string, "authorization", "secret")

    assert secret == fake_secret
  end
end
