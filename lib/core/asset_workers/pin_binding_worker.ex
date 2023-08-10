defimpl FarmbotOS.AssetWorker, for: FarmbotOS.Asset.PinBinding do
  @moduledoc """
  Worker for monitoring hardware GPIO. (not related to the mcu firmware.)

  Upon a button trigger, a `sequence`, or `special_action` will be executed by
  the CeleryScript Runtime.

  This module also defines a behaviour that allows for abstracting and testing
  independent of GPIO hardware code.
  """

  use GenServer
  require Logger
  require FarmbotOS.Logger

  alias FarmbotOS.{
    Asset.PinBinding,
    Asset.Sequence,
    Asset
  }

  alias FarmbotOS.Celery.AST

  @error_retry_time_ms 5000

  @gpio_handler Application.compile_env(:farmbot, __MODULE__)[:gpio_handler]
  @gpio_handler ||
    Mix.raise("""
      config :farmbot, #{__MODULE__}, gpio_handler: MyModule
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
  def preload(%PinBinding{}), do: []

  @impl true
  def tracks_changes?(%PinBinding{}), do: false

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
    {:ok, %{pin_binding: pin_binding}, 0}
  end

  @impl true
  def handle_cast(
        :trigger,
        %{pin_binding: %{special_action: nil} = pin_binding} = state
      ) do
    case Asset.get_sequence(pin_binding.sequence_id) do
      %Sequence{name: name} = seq ->
        FarmbotOS.Logger.info(
          1,
          "#{pin_binding} triggered, executing #{name}"
        )

        AST.decode(seq)
        |> execute(state)

      nil ->
        FarmbotOS.Logger.error(
          1,
          "Failed to find associated Sequence for: #{pin_binding}"
        )

        {:noreply, state}
    end
  end

  def handle_cast(
        :trigger,
        %{pin_binding: %{special_action: "emergency_lock"} = pin_binding} =
          state
      ) do
    FarmbotOS.Logger.info(
      1,
      "#{pin_binding} triggered, executing Emergency Lock"
    )

    AST.Factory.new()
    |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
    |> AST.Factory.emergency_lock()
    |> execute(state)
  end

  def handle_cast(
        :trigger,
        %{pin_binding: %{special_action: "emergency_unlock"} = pin_binding} =
          state
      ) do
    FarmbotOS.Logger.info(
      1,
      "#{pin_binding} triggered, executing Emergency Unlock"
    )

    AST.Factory.new()
    |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
    |> AST.Factory.emergency_unlock()
    |> execute(state)
  end

  def handle_cast(
        :trigger,
        %{pin_binding: %{special_action: "power_off"} = pin_binding} = state
      ) do
    FarmbotOS.Logger.info(1, "#{pin_binding} triggered, executing Power Off")

    AST.Factory.new()
    |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
    |> AST.Factory.power_off()
    |> execute(state)
  end

  def handle_cast(
        :trigger,
        %{pin_binding: %{special_action: "read_status"} = pin_binding} = state
      ) do
    FarmbotOS.Logger.info(
      1,
      "#{pin_binding} triggered, executing Read Status"
    )

    AST.Factory.new()
    |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
    |> AST.Factory.read_status()
    |> execute(state)
  end

  def handle_cast(
        :trigger,
        %{pin_binding: %{special_action: "reboot"} = pin_binding} = state
      ) do
    FarmbotOS.Logger.info(1, "#{pin_binding} triggered, executing Reboot")
    FarmbotOS.Celery.SysCallGlue.reboot()
    {:noreply, state}
  end

  def handle_cast(
        :trigger,
        %{pin_binding: %{special_action: "sync"} = pin_binding} = state
      ) do
    FarmbotOS.Logger.info(1, "#{pin_binding} triggered, executing Sync")
    FarmbotOS.Celery.SysCallGlue.sync()
    {:noreply, state}
  end

  def handle_cast(
        :trigger,
        %{pin_binding: %{special_action: "take_photo"} = pin_binding} = state
      ) do
    FarmbotOS.Logger.info(1, "#{pin_binding} triggered, executing Take Photo")

    AST.Factory.new()
    |> AST.Factory.rpc_request("pin_binding.#{pin_binding.pin_num}")
    |> AST.Factory.take_photo()
    |> execute(state)
  end

  def handle_cast(:trigger, %{pin_binding: pin_binding} = state) do
    FarmbotOS.Logger.error(1, "Unknown PinBinding: #{pin_binding}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:timeout, %{pin_binding: pin_binding} = state) do
    worker_pid = self()

    case gpio_handler().start_link(pin_binding.pin_num, fn ->
           trigger(worker_pid)
         end) do
      {:ok, pid} when is_pid(pid) ->
        Process.link(pid)
        {:noreply, state}

      {:error, {:already_started, pid}} ->
        Process.link(pid)
        {:noreply, state}

      {:error, reason} ->
        Logger.error(
          "Failed to start PinBinding GPIO Handler: #{inspect(reason)}"
        )

        {:noreply, state, @error_retry_time_ms}

      :ignore ->
        Logger.info("Failed to start PinBinding GPIO Handler. Not retrying.")
        {:noreply, state}
    end
  end

  def handle_info({:csvm_done, _ref, _result}, state) do
    {:noreply, state}
  end

  defp execute(%AST{} = ast, state) do
    case FarmbotOS.Celery.execute(ast, make_ref()) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("BAD AST: " <> inspect(ast))

        FarmbotOS.Logger.error(
          1,
          "error executing #{state.pin_binding}: #{reason}"
        )
    end

    {:noreply, state}
  end

  defp gpio_handler,
    do: Application.get_env(:farmbot, __MODULE__)[:gpio_handler]
end
