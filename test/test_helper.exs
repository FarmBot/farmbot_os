ExUnit.start
IO.puts "starting test genserver"
Code.load_file("test_genserver.ex", "./test")
Code.ensure_loaded(TestGenServer)
Code.load_file("fake_mqtt.ex", "./test")
Code.ensure_loaded(FakeMqtt)
Code.load_file("fake_net_man.ex", "./test")
Code.ensure_loaded(NetMan)
{:ok, _} = TestGenServer.start_link(SafeStorage)
{:ok, _botState} = Farmbot.BotState.start_link(:nothing)
