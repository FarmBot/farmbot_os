defmodule Farmbot.System.GPIO do
  @moduledoc "Handles GPIO inputs."
  use GenStage
  use Farmbot.Logger

  @handler Application.get_env(:farmbot, :behaviour)[:gpio_handler]

  @doc "Register a pin number to execute sequence."
  def register_sequence(pin_num, sequence_id) do
    GenStage.call(__MODULE__, {:register_sequence, pin_num, sequence_id})
  end

  @doc false
  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  defmodule State do
    @moduledoc false
    defstruct [registered: %{}, handler: nil]
  end

  def init([]) do
    case @handler.start_link() do
      {:ok, handler} ->
        {:producer_consumer, struct(State, [handler: handler]), subscribe_to: [handler], dispatcher: GenStage.BroadcastDispatcher}
      err -> err
    end
  end

  def handle_events(pin_triggers, _from, state) do
    t = Enum.uniq(pin_triggers)
    IO.puts "Got triggers: #{inspect t}"
    for {:pin_trigger, pin} <- t do
      sequence_id = state.registered[pin]
      if sequence_id do
        Logger.busy 1, "Starting Sequence: #{sequence_id} from pin: #{pin}"
        Farmbot.CeleryScript.AST.Node.Execute.execute(%{sequence_id: sequence_id}, [], struct(Macro.Env, []))
      else
        Logger.warn 3, "No sequence assosiated with: #{pin}"
      end
    end
    {:noreply, [], state}
  end

  def handle_call({:register_sequence, pin_num, sequence_id}, _from, state) do
    case @handler.register_pin(pin_num) do
      :ok -> {:reply, :ok, [], %{state | registered: Map.put(state.registered, pin_num, sequence_id)}}
      {:error, _} = err -> {:reply, err, [], state}
    end
  end

  def terminate(reason, state) do
    if state.handler do
      if Process.alive?(state.handler) do
        GenStage.stop(state.handler, reason)
      end
    end
  end

end
