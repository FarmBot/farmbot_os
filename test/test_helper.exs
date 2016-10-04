ExUnit.start
# Maybe we will need a "test supervision tree" LOL
{:ok, _pid} = BotStatus.start_link(:nothing)
