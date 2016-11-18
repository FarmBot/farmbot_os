ExUnit.start
IO.puts "starting test genserver"
Code.load_file("test_genserver.ex", "./test")
Code.ensure_loaded(TestGenServer)
Code.load_file("fake_mqtt.ex", "./test")
Code.ensure_loaded(FakeMqtt)
Code.load_file("fake_net_man.ex", "./test")
Code.ensure_loaded(NetMan)
# Start safe storage (in dev mode)
{:ok, _} = TestGenServer.start_link(SafeStorage)

# Start farmbot auth
{:ok, _fb_auth} = Farmbot.Auth.start(:normal, [])

#FIXME
{:ok, _botState} = Farmbot.BotState.start_link(
      %{target: "test", compat_version: 0, env: :test, version: "2.1.4"})
