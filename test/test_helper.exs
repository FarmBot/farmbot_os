ExUnit.start
# Maybe we will need a "test supervision tree" LOL
{:ok, _pid} = BotState.start_link(:nothing)
