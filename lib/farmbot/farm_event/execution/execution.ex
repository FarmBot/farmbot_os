defprotocol Farmbot.FarmEvent.Execution do
  @moduledoc """
  Protocol to be implemented by any struct that can be executed by
  Farmbot.FarmEvent.Manager.
  """
  @dialyzer {:nowarn_function, __protocol__: 1}

  @typedoc "Data to be executed."
  @type data :: map

  @doc """
  Execute an item.
  * `data`    - A `Farmbot.Database.Syncable` struct that is implemented.
  * `now`     - `DateTime` of execution.
  """
  @spec execute_event(data, DateTime.t) :: any
  def execute_event(data, now)
end
