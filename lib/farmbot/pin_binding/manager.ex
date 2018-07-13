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

  def confirm_asset_storage_up do
    GenStage.call(__MODULE__, :confirm_asset_storage_up)
  end

  @doc false
  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  defmodule State do
    @moduledoc false
    defstruct repo_up: false,
              registered: %{},
              handler: nil,
              env: struct(Macro.Env, [])
  end

  def init([]) do
    case @handler.start_link() do
      {:ok, handler} ->
        state = initial_state([], struct(State, handler: handler))
        {:producer_consumer, state,
         subscribe_to: [handler], dispatcher: GenStage.BroadcastDispatcher}

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
    %{state | registered: Map.put(state.registered, pin, binding)}
  end

  defp do_unregister(state, %PinBinding{pin_num: pin_num}) do
    %{state | registered: Map.delete(state.registered, pin_num)}
  end

  def handle_events(_, _, %{repo_up: false} = state) do
    Logger.warn(3, "Not handling gpio events until Asset storage is up.")
    {:noreply, [], state}
  end

  def handle_events(pin_triggers, _from, state) do
    t = Enum.uniq(pin_triggers)

    new_env =
      Enum.reduce(t, state.env, fn {:pin_trigger, pin}, env ->
        binding = state.registered[pin]

        if binding do
          Logger.busy(1, "PinBinding #{pin} triggered.")
          %Macro.Env{} = do_execute(binding, env)
        else
          Logger.warn(3, "No sequence assosiated with: #{pin}")
          env
        end
      end)

    {:noreply, [], %{state | env: new_env}}
  end

  def handle_call({:register_pin, %PinBinding{pin_num: pin_num} = binding}, _from, state) do
    Logger.info 1, "Registering PinBinding #{pin_num}"
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

  def handle_call({:unregister_pin, %PinBinding{pin_num: pin_num}}, _from, state) do
    case state.registered[pin_num] do
      nil ->
        {:reply, {:error, :unregistered}, [], state}

      %PinBinding{} = old ->
        Logger.info 1, "Unregistering PinBinding #{pin_num}"
        case @handler.unregister_pin(pin_num) do
          :ok ->
            new_state = do_unregister(state, old)
            {:reply, :ok, [{:gpio_registry, %{}}], new_state}

          err ->
            {:reply, err, [], state}
        end
    end
  end

  def handle_call(:confirm_asset_storage_up, _, state) do
    all_bindings = Asset.all_pin_bindings()
    state = initial_state(all_bindings, state)
    {:reply, :ok, [], %{state | repo_up: true}}
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
end
