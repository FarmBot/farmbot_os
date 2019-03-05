defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.PinBinding do
  use GenServer
  require Logger
  require FarmbotCore.Logger

  alias FarmbotCore.{
    Asset.PinBinding,
    Asset.Sequence,
    Asset
  }

  alias FarmbotCeleryScript.{AST, Scheduler}

  @error_retry_time_ms Application.get_env(:farmbot_core, __MODULE__)[:error_retry_time_ms]

  @gpio_handler Application.get_env(:farmbot_core, __MODULE__)[:gpio_handler]
  @gpio_handler ||
    Mix.raise("""
      config :farmbot_core, #{__MODULE__}, gpio_handler: MyModule
    """)

  @error_retry_time_ms ||
    Mix.raise("""
      config :farmbot_core, #{__MODULE__}, error_retry_time_ms: 30_000
    """)

  @typedoc "Opaque function that should be called upon a trigger"
  @type trigger_fun :: (pid -> any)

  @typedoc "Integer representing a GPIO on the target platform."
  @type pin_number :: integer

  @doc """
  Start a GPIO Handler. Returns the same values as a GenServer start.

  Should call `#{__MODULE__}.trigger/1` when a pin has been triggered.
  """
  @callback start_link(pin_number, trigger_fun) :: GenServer.on_start()

  @impl true
  def preload(_), do: []

  @impl true
  def start_link(%PinBinding{} = pin_binding, _args) do
    GenServer.start_link(__MODULE__, %PinBinding{} = pin_binding)
  end

  # This function is opaque and should be considered private.
  @doc false
  def trigger(pid) do
    GenServer.cast(pid, :trigger)
  end

  @impl true
  def init(%PinBinding{} = pin_binding) do
    {:ok, %{pin_binding: pin_binding, scheduled_ref: nil}, 0}
  end

  @impl true
  def handle_cast(:trigger, %{pin_binding: %{special_action: nil} = pin_binding} = state) do
    case Asset.get_sequence(id: pin_binding.sequence_id) do
      %Sequence{} = seq ->
        ref = Scheduler.schedule(seq)
        {:noreply, %{state | scheduled_ref: ref}, :hibernate}

      nil ->
        FarmbotCore.Logger.error(1, "Failed to find assosiated Sequence for: #{pin_binding}")
        {:noreply, state, :hibernate}
    end
  end

  def handle_cast(:trigger, %{pin_binding: %{special_action: "dump_info"} = pin_binding} = state) do
    ref =
      AST.Factory.new()
      |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
      |> AST.Factory.dump_info()
      |> Scheduler.schedule()
    {:noreply, %{state | scheduled_ref: ref}, :hibernate}
  end

  def handle_cast(:trigger, %{pin_binding: %{special_action: "emergency_lock"} = pin_binding} = state) do
    ref =
      AST.Factory.new()
      |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
      |> AST.Factory.emergency_lock()
      |> Scheduler.schedule()
    {:noreply, %{state | scheduled_ref: ref}, :hibernate}
  end

  def handle_cast(:trigger, %{pin_binding: %{special_action: "emergency_unlock"} = pin_binding} = state) do
    ref =
      AST.Factory.new()
      |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
      |> AST.Factory.emergency_unlock()
      |> Scheduler.schedule()
    {:noreply, %{state | scheduled_ref: ref}, :hibernate}
  end

  def handle_cast(:trigger, %{pin_binding: %{special_action: "power_off"} = pin_binding} = state) do
    ref =
      AST.Factory.new()
      |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
      |> AST.Factory.power_off()
      |> Scheduler.schedule()
    {:noreply, %{state | scheduled_ref: ref}, :hibernate}
  end

  def handle_cast(:trigger, %{pin_binding: %{special_action: "read_status"} = pin_binding} = state) do
    ref =
      AST.Factory.new()
      |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
      |> AST.Factory.read_status()
      |> Scheduler.schedule()
    {:noreply, %{state | scheduled_ref: ref}, :hibernate}
  end

  def handle_cast(:trigger, %{pin_binding: %{special_action: "reboot"} = pin_binding} = state) do
    ref =
      AST.Factory.new()
      |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
      |> AST.Factory.reboot()
      |> Scheduler.schedule()
    {:noreply, %{state | scheduled_ref: ref}, :hibernate}
  end

  def handle_cast(:trigger, %{pin_binding: %{special_action: "sync"} = pin_binding} = state) do
    ref =
      AST.Factory.new()
      |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
      |> AST.Factory.sync()
      |> Scheduler.schedule()
    {:noreply, %{state | scheduled_ref: ref}, :hibernate}
  end

  def handle_cast(:trigger, %{pin_binding: %{special_action: "take_photo"} = pin_binding} = state) do
    ref =
      AST.Factory.new()
      |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
      |> AST.Factory.take_photo()
      |> Scheduler.schedule()
    {:noreply, %{state | scheduled_ref: ref}, :hibernate}
  end

  def handle_cast(:trigger, %{pin_binding: pin_binding} = state) do
    FarmbotCore.Logger.error(1, "Unknown PinBinding: #{pin_binding}")
    {:noreply, state, :hibernate}
  end

  @impl true
  def handle_info(:timeout, %{pin_binding: pin_binding} = state) do
    worker_pid = self()

    case gpio_handler().start_link(pin_binding.pin_num, fn -> trigger(worker_pid) end) do
      {:ok, pid} when is_pid(pid) ->
        Process.link(pid)
        {:noreply, state}

      {:error, {:already_started, pid}} ->
        Process.link(pid)
        {:noreply, state, :hibernate}

      {:error, reason} ->
        Logger.error("Failed to start PinBinding GPIO Handler: #{inspect(reason)}")
        {:noreply, state, @error_retry_time_ms}

      :ignore ->
        Logger.info("Failed to start PinBinding GPIO Handler. Not retrying.")
        {:noreply, state, :hibernate}
    end
  end

  @impl true
  def handle_info({Scheduler, ref, :ok}, %{scheduled_ref: ref} = state) do
    {:noreply, state, :hibernate}
  end

  def handle_info({Scheduler, ref, {:error, reason}}, %{scheduled_ref: ref} = state) do
    pin_binding = state.pin_binding
    FarmbotCore.Logger.error(1, "PinBinding: #{pin_binding} failed to execute: #{reason}")
    {:noreply, state, :hibernate}
  end

  defp gpio_handler,
    do: Application.get_env(:farmbot_core, __MODULE__)[:gpio_handler]
end
