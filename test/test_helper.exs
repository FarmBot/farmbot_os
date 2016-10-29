ExUnit.start
IO.puts "starting test genserver"
Code.load_file("test_genserver.ex", "./test")
Code.ensure_loaded(TestGenServer)
Code.load_file("fake_mqtt.ex", "./test")
Code.ensure_loaded(FakeMqtt)
{:ok, _} = TestGenServer.start_link(SafeStorage)
{:ok, _} = TestGenServer.start_link(Wifi)
{:ok, _botState} = BotState.start_link(:nothing)
