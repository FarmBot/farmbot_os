defmodule Farmbot.System.GPIO do
  @moduledoc "Handles GPIO inputs."
  use GenStage
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.GpioRegistry

  @handler Application.get_env(:farmbot, :behaviour)[:gpio_handler]

  @doc "Register a pin number to execute sequence."
  def register_pin(pin_num, sequence_id) do
    GenStage.call(__MODULE__, {:register_pin, pin_num, sequence_id})
  end

  @doc "Unregister a sequence."
  def unregister_pin(sequence_id) do
    GenStage.call(__MODULE__, {:unregister_pin, sequence_id})
  end

  def confirm_asset_storage_up do
    GenStage.call(__MODULE__, :confirm_asset_storage_up)
  end

  @doc false
  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  defmodule State do
    @moduledoc false
    defstruct [repo_up: false, registered: %{}, handler: nil, env: struct(Macro.Env, [])]
  end

  def init([]) do
    case @handler.start_link() do
      {:ok, handler} ->
        all_gpios = ConfigStorage.all(GpioRegistry)
        state = initial_state(all_gpios, struct(State, [handler: handler]))
        Process.send_after(self(), :update_fb_state_tree, 10)
        {:producer_consumer, state, subscribe_to: [handler], dispatcher: GenStage.BroadcastDispatcher}
      err -> err
    end
  end

  defp initial_state([], state), do: state

  defp initial_state([%GpioRegistry{pin: pin, sequence_id: sequence_id} | rest], state) do
    case @handler.register_pin(pin) do
      :ok -> initial_state(rest, %{state | registered: Map.put(state.registered, pin, sequence_id)})
      _ -> initial_state(rest, state)
    end
  end

  def handle_events(_, _, %{repo_up: false} = state) do
    Logger.warn 3, "Not handling gpio events until Asset storage is up."
    {:noreply, [], state}
  end

  def handle_events(pin_triggers, _from, state) do
    t = Enum.uniq(pin_triggers)
    new_env = Enum.reduce(t, state.env, fn({:pin_trigger, pin}, env) ->
      sequence_id = state.registered[pin]
      if sequence_id do
        Logger.busy 1, "Starting Sequence: #{sequence_id} from pin: #{pin}"
        do_execute(sequence_id, env)
      else
        Logger.warn 3, "No sequence assosiated with: #{pin}"
        env
      end
    end)
    {:noreply, [], %{state | env: new_env}}
  end

  def handle_info(:update_fb_state_tree, state) do
    {:noreply, [{:gpio_registry, state.registered}], state}
  end

  def handle_call({:register_pin, pin_num, sequence_id}, _from, state) do
    case state.registered[pin_num] do
      nil ->
        case @handler.register_pin(pin_num) do
          :ok ->
            reg = struct(GpioRegistry, [pin: pin_num, sequence_id: sequence_id])
            ConfigStorage.insert!(reg)
            new_state = %{state | registered: Map.put(state.registered, pin_num, sequence_id)}
            {:reply, :ok, [{:gpio_registry, new_state.registered}], new_state}
          {:error, _} = err -> {:reply, err, [], state}
        end
      _ -> {:reply, {:error, :already_registered}, [], state}
    end

  end

  def handle_call({:unregister_pin, pin_num}, _from, state) do
    case state.registered[pin_num] do
      nil -> {:reply, {:error, :unregistered}, [], state}
      sequence_id ->
        case @handler.unregister_pin(pin_num) do
          :ok ->
            do_delete(pin_num, sequence_id)
            new_state = %{state | registered: Map.delete(state.registered, pin_num)}
            {:reply, :ok, [{:gpio_registry, new_state.registered}], new_state}
          err -> {:reply, err, [], state}
        end
    end
  end

  def handle_call(:confirm_asset_storage_up, _, state) do
    {:reply, :ok, [], %{state | repo_up: true}}
  end

  def terminate(reason, state) do
    if state.handler do
      if Process.alive?(state.handler) do
        GenStage.stop(state.handler, reason)
      end
    end
  end

  defp do_delete(pin_num, sequence_id) do
    import Ecto.Query
    case ConfigStorage.one(from g in GpioRegistry, where: g.pin == ^pin_num and g.sequence_id == ^sequence_id) do
      nil -> :ok
      obj -> ConfigStorage.delete!(obj)
    end
  end

  defp do_execute(sequence_id, env) do
    import Farmbot.CeleryScript.AST.Node.Execute, only: [execute: 3]
    try do
      case execute(%{sequence_id: sequence_id}, [], env) do
        {:ok, env} -> env
        {:error, _, env} -> env
      end
    rescue
      err ->
        message = Exception.message(err)
        Logger.warn 2, "Failed to execute sequence #{sequence_id} " <> message
        env
    end
  end

end
