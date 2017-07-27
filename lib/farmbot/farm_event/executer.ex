defprotocol Farmbot.FarmEvent.Executer do
  @moduledoc """
  Protocol to be implemented by any struct that can be executed by
  Farmbot.FarmEvent.Runner.
  """

  @typedoc "Data to be executed."
  @type data :: map

  @doc """
  Execute an item.
  * `data`    - A `Farmbot.Database.Syncable` struct that is implemented.
  * `context` - `Farmbot.Context` struct
  * `now`     - `DateTime` of execution.
  """
  @spec execute_event(data, Farmbot.Context.t, DateTime.t) :: any
  def execute_event(data, context, now)
end
