defprotocol Farmbot.FarmEvent.Executer do
  # @fallback_to_any true
  @doc """
    Execute an item.
  """
  def execute_event(data, context, now)
end

# defimpl Farmbot.FarmEvent.Executer, for: Any do
#   def execute(context, data) do
#     raise "This is kind of redundant"
#   end
# end
