defmodule Farmbot.PinBinding.Manager do
  @moduledoc "Handles PinBinding inputs and outputs"
  use GenServer
  require Farmbot.Logger
  alias __MODULE__, as: State
  alias Farmbot.Asset
  alias Asset.{PinBinding, Sequence}
  @handler Application.get_env(:farmbot_core, :behaviour)[:pin_binding_handler]
  @handler || Mix.raise("No pin binding handler.")

  defstruct registered: %{},
            signal: %{},
            handler: nil

  # Should be called by a handler
  @doc false
  def trigger(pin, signal) do
    GenServer.cast(__MODULE__, {:pin_trigger, pin, signal})
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    case @handler.start_link() do
      {:ok, handler} ->
        Farmbot.Registry.subscribe(self())
        all = Asset.all_pin_bindings()
        {:ok, initial_state(all, %State{handler: handler})}
      err ->
        err
    end
  end

  def terminate(reason, state) do
    if state.handler do
      if Process.alive?(state.handler) do
        GenStage.stop(state.handler, reason)
      end
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

  def handle_cast({:pin_trigger, pin, :falling}, state) do
    binding = state.registered[pin]
    if binding do
      do_usr_led(binding, :off)
      if state.signal[pin] do
        Process.cancel_timer(state.signal[pin])
        {:noreply, %{state | signal: Map.put(state.signal, pin, debounce_timer(pin))}}
      else
        Farmbot.Logger.busy(1, "Pin Binding #{binding} triggered #{binding.special_action || "execute_sequence"}")
        do_execute(binding)
        {:noreply, %{state | signal: Map.put(state.signal, pin, debounce_timer(pin))}}
      end
    else
      Farmbot.Logger.warn(3, "No Pin Binding assosiated with: #{pin}")
      {:noreply, state}
    end
  end

  def handle_cast({:pin_trigger, pin, :rising}, state) do
    binding = state.registered[pin]
    if binding do
      do_usr_led(binding, :solid)
    end
    {:noreply, state}
  end

  def handle_info({pin, :ok}, state) do
    {:noreply, %{state | signal: Map.put(state.signal, pin, nil)}}
  end

  def handle_info({Farmbot.Registry, {Asset, {:addition, %PinBinding{} = binding}}}, state) do
    state = register_pin(state, binding)
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, {Asset, {:deletion, %PinBinding{} = binding}}}, state) do
    state = unregister_pin(state, binding)
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, {Asset, {:update, %PinBinding{} = binding}}}, state) do
    state = state
    |> unregister_pin(binding)
    |> register_pin(binding)
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, _}, state) do
    {:noreply, state}
  end

  defp register_pin(state, %PinBinding{pin_num: pin_num} = binding) do
    case state.registered[pin_num] do
      nil ->
        case @handler.register_pin(pin_num) do
          :ok -> do_register(state, binding)

          {:error, reason} ->
            error_log("registering", binding, inspect reason)
            state
        end

      _ ->
        error_log("registering", binding, "already registered")
        state
    end
  end

  def unregister_pin(state, %PinBinding{pin_num: pin_num} = binding) do
    case state.registered[pin_num] do
      nil ->
        error_log("unregistering", binding, "not registered")
        state

      %PinBinding{} = old ->
        case @handler.unregister_pin(pin_num) do
          :ok ->
            do_unregister(state, old)

          {:error, reason} ->
            error_log("unregistering", binding, inspect reason)
            state
        end
    end
  end

  defp error_log(action_verb, binding , reason) do
    Farmbot.Logger.error 1, "Error #{action_verb} Pin Binding #{binding} (#{reason})"
  end

  defp do_register(state, %PinBinding{pin_num: pin} = binding) do
    Farmbot.Logger.debug 1, "Pin Binding #{binding} registered."
    %{state | registered: Map.put(state.registered, pin, binding), signal: Map.put(state.signal, pin, nil)}
  end

  defp do_unregister(state, %PinBinding{pin_num: pin_num} = binding) do
    Farmbot.Logger.debug 1, "Pin Binding #{binding} unregistered."
    %{state | registered: Map.delete(state.registered, pin_num), signal: Map.delete(state.signal, pin_num)}
  end

  defp do_execute(%PinBinding{sequence_id: sequence_id} = binding) when is_number(sequence_id) do
    sequence_id
    |> Farmbot.Asset.get_sequence_by_id!()
    |> Farmbot.Core.CeleryScript.sequence(&execute_results(&1, binding))
  end

  defp do_execute(%PinBinding{special_action: action} = binding) when is_binary(action) do
    %Sequence{
      id: 0,
      name: action,
      kind: action,
      args: %{},
      body: [] }
    |> Farmbot.Core.CeleryScript.sequence(&execute_results(&1, binding))
  end

  @doc false
  def execute_results(:ok, binding) do
    Farmbot.Logger.success(1, "Pin Binding #{binding} execution complete.")
  end

  def execute_results({:error, _}, binding) do
    Farmbot.Logger.error(1, "Pin Binding #{binding} execution failed.")
  end

  defp debounce_timer(pin) do
    Process.send_after(self(), {pin, :ok}, 200)
  end

  defp do_usr_led(%PinBinding{pin_num: 26}, signal), do: do_write(:white1, signal)
  defp do_usr_led(%PinBinding{pin_num: 5}, signal), do: do_write(:white2, signal)
  defp do_usr_led(%PinBinding{pin_num: 20}, signal), do: do_write(:white3, signal)
  defp do_usr_led(_, _), do: :ok
  defp do_write(led, signal), do: apply(Farmbot.Leds, led, [signal])
end
