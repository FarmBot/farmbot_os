# def BotCommandEventHandler do
#   use GenEvent
#
#   def handle_event({:bot_command, command}, commands) do
#     {:ok, [x | commands]}
#   end
#
#   def handle_call(:commands, commands) do
#     {:ok, Enum.reverse(commands), []}
#   end
# end
#
# def BotCommandHandler do
#   use GenServer
#   def start_link(args) do
#     GenServer.start_link(__MODULE__, args, name: __MODULE__)
#   end
#
#   def init(args) do
#     {:ok, pid} = GenEvent.start_link([])
#     GenEvent.add_handler(pid, BotCommandEventHandler, [])
#     {:ok, pid}
#   end
#
#   def handle_call({:move_absolute, {x,y,z,s}, _from, state) do
#     {:reply,GenServer.call(NewHandler, "G00 X#{x} Y#{y} Z#{z} S#{s}") ,state}
#   end
# end
