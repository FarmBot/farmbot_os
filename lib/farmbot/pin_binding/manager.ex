defmodule Farmbot.PinBinding.Manager do
  @moduledoc "Handles PinBinding inputs and outputs"
  use GenStage
  use Farmbot.Logger
  alias Farmbot.Asset
  alias Asset.PinBinding
  @handler Application.get_env(:farmbot, :behaviour)[:pin_binding_handler]
  @handler || Mix.raise("No pin binding handler.")

  @doc "Register a pin number to execute sequence."
  def register_pin(%PinBinding{} = binding) do
    GenStage.call(__MODULE__, {:register_pin, binding})
  end

  @doc "Unregister a sequence."
  def unregister_pin(%PinBinding{} = binding) do
    GenStage.call(__MODULE__, {:unregister_pin, binding})
  end

  def trigger(pin, signal) do
    GenStage.cast(__MODULE__, {:trigger, pin, signal})
  end

  def confirm_asset_storage_up do
    send __MODULE__, :confirm_asset_storage_up
  end

  @doc false
  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  defmodule State do
    @moduledoc false
    defstruct repo_up: false,
              registered: %{},
              signal: %{},
              handler: nil,
              env: struct(Macro.Env, [])
  end

  def init([]) do
    case @handler.start_link() do
      {:ok, handler} ->
        if Process.whereis(Farmbot.Repo) do
          confirm_asset_storage_up()
        end
        state = initial_state([], struct(State, handler: handler))
        {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
      err ->
        err
    end
  end

  defp initial_state([], state), do: state

  defp initial_state([%PinBinding{pin_num: pin} = binding | rest], state) do
    case @handler.register_pin(pin) do
      :ok ->
        new_state = do_register(state, binding)
        initial_state(rest, new_state)
      _ ->
        initial_state(rest, state)
    end
  end

  defp do_register(state, %PinBinding{pin_num: pin} = binding) do
    %{state | registered: Map.put(state.registered, pin, binding), signal: Map.put(state.signal, pin, nil)}
  end

  defp do_unregister(state, %PinBinding{pin_num: pin_num}) do
    %{state | registered: Map.delete(state.registered, pin_num), signal: Map.delete(state.signal, pin_num)}
  end

  def handle_events(_, _, %{repo_up: false} = state) do
    Logger.warn(3, "Not handling gpio events until Asset storage is up.")
    {:noreply, [], state}
  end

  def handle_events(_, _from, state) do
    {:noreply, [], state}
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_cast({:trigger, _, _}, %{repo_up: false} = state) do
    Logger.debug 3, "Asset storage not up"
    {:noreply, [], state}
  end

  def handle_cast({:trigger, pin, :falling}, state) do
    binding = state.registered[pin]
    if binding do
      do_usr_led(binding, :off)
      if state.signal[pin] do
        IO.puts "[#{pin}] #{binding} is in debounced state"
        Process.cancel_timer(state.signal[pin])
        {:noreply, [], %{state | signal: Map.put(state.signal, pin, debounce_timer(binding))}}
      else
        Logger.busy(1, "Pin Binding #{binding} triggered #{binding.special_action || "execute_sequence"}")
        env = %Macro.Env{} = do_execute(binding, state.env)
        {:noreply, [], %{state | env: env, signal: Map.put(state.signal, pin, debounce_timer(binding))}}
      end
    else
      Logger.warn(3, "No Pin Binding assosiated with: #{pin}")
      {:noreply, [], state}
    end
  end

  def handle_cast({:trigger, pin, :rising}, state) do
    binding = state.registered[pin]
    if binding do
      do_usr_led(binding, :solid)
    end
    {:noreply, [], state}
  end


  def handle_info(:confirm_asset_storage_up, state) do
    all_bindings = Asset.all_pin_bindings()
    state = initial_state(all_bindings, state)
    {:noreply, [], %{state | repo_up: true}}
  end

  def handle_info({:debounce, %PinBinding{pin_num: pin_num} = binding}, state) do
    IO.puts "[#{pin_num}] #{binding} debounce state clear."
    {:noreply, [], %{state | signal: Map.put(state.signal, pin_num, nil)}}
  end

  def handle_call({:register_pin, %PinBinding{pin_num: pin_num} = binding}, _from, state) do
    Logger.debug 1, "Pin Binding #{binding} registered."
    case state.registered[pin_num] do
      nil ->
        case @handler.register_pin(pin_num) do
          :ok ->
            new_state = do_register(state, binding)
            {:reply, :ok, [{:gpio_registry, %{}}], new_state}

          {:error, _} = err ->
            {:reply, err, [], state}
        end

      _ ->
        {:reply, {:error, :already_registered}, [], state}
    end
  end

  def handle_call({:unregister_pin, %PinBinding{pin_num: pin_num} = binding}, _from, state) do
    case state.registered[pin_num] do
      nil ->
        {:reply, {:error, :unregistered}, [], state}

      %PinBinding{} = old ->
        Logger.debug 1, "Pin Binding #{binding} unregistered."
        case @handler.unregister_pin(pin_num) do
          :ok ->
            new_state = do_unregister(state, old)
            {:reply, :ok, [{:gpio_registry, %{}}], new_state}

          err ->
            {:reply, err, [], state}
        end
    end
  end

  def terminate(reason, state) do
    if state.handler do
      if Process.alive?(state.handler) do
        GenStage.stop(state.handler, reason)
      end
    end
  end

  defp do_execute(%PinBinding{pin_num: num, special_action: kind}, env) when is_binary(kind) do
    celery = %{kind: kind, args: %{}, body: []}
    {:ok, seq} = Farmbot.CeleryScript.AST.decode(celery)
    try do
      case Farmbot.CeleryScript.execute(seq, env) do
        {:ok, env} -> env
        {:error, _, env} -> env
      end
    rescue
      err ->
        message = Exception.message(err)
        Logger.warn(2, "Failed to execute sequence PinBinding #{num}:  " <> message)
        IO.warn "", System.stacktrace()
        env
    end
  end

  defp do_execute(%PinBinding{sequence_id: sequence_id}, env) when is_integer(sequence_id) do
    import Farmbot.CeleryScript.AST.Node.Execute, only: [execute: 3]

    try do
      case execute(%{sequence_id: sequence_id}, [], env) do
        {:ok, env} -> env
        {:error, _, env} -> env
      end
    rescue
      err ->
        message = Exception.message(err)
        Logger.warn(2, "Failed to execute sequence #{sequence_id} " <> message)
        IO.warn "", System.stacktrace()
        env
    end
  end

  defp debounce_timer(%PinBinding{} = binding) do
    Process.send_after(self(), {:debounce, binding}, 200)
  end

  defp do_usr_led(%PinBinding{pin_num: 26}, signal), do: do_write(:white1, signal)
  defp do_usr_led(%PinBinding{pin_num: 5}, signal), do: do_write(:white2, signal)
  defp do_usr_led(%PinBinding{pin_num: 20}, signal), do: do_write(:white3, signal)
  defp do_usr_led(_, _), do: :ok
  defp do_write(led, signal), do: apply(Farmbot.Leds, led, [signal])
end
