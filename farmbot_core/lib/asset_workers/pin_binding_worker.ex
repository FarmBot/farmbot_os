defimpl Farmbot.AssetWorker, for: Farmbot.Asset.PinBinding do
  @gpio_handler Application.get_env(:farmbot_core, __MODULE__)[:gpio_handler]
  @error_retry_time_ms Application.get_env(:farmbot_core, __MODULE__)[:error_retry_time_ms]

  require Logger
  require Farmbot.Logger
  import Farmbot.CeleryScript.Utils

  alias Farmbot.{
    Core.CeleryScript,
    Asset.PinBinding,
    Asset.Sequence,
    Asset
  }

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

  use GenServer

  def start_link(%PinBinding{} = pin_binding) do
    GenServer.start_link(__MODULE__, [%PinBinding{} = pin_binding])
  end

  # This function is opaque and should be considered private.
  @doc false
  def trigger(pid) do
    GenServer.cast(pid, :trigger)
  end

  def init([%PinBinding{} = pin_binding]) do
    {:ok, pin_binding, 0}
  end

  def handle_info(:timeout, %PinBinding{} = pin_binding) do
    worker_pid = self()

    case @gpio_handler.start_link(pin_binding.pin_num, fn -> trigger(worker_pid) end) do
      {:ok, pid} when is_pid(pid) ->
        Process.link(pid)
        {:noreply, pin_binding}

      {:error, {:already_started, pid}} ->
        Process.link(pid)
        {:noreply, pin_binding, :hibernate}

      {:error, reason} ->
        Logger.error("Failed to start PinBinding GPIO Handler: #{inspect(reason)}")
        {:noreply, pin_binding, @error_retry_time_ms}

      :ignore ->
        Logger.info("Failed to start PinBinding GPIO Handler. Not retrying.")
        {:noreply, pin_binding, :hibernate}
    end
  end

  def handle_cast(:trigger, %PinBinding{special_action: nil} = pin_binding) do
    case Asset.get_sequence(id: pin_binding.sequence_id) do
      %Sequence{} = seq ->
        pid = CeleryScript.sequence(seq, &handle_sequence_results(&1, pin_binding))
        Process.link(pid)
        {:noreply, pin_binding, :hibernate}

      nil ->
        Farmbot.Logger.error(1, "Failed to find assosiated Sequence for: #{pin_binding}")
        {:noreply, pin_binding, :hibernate}
    end
  end

  def handle_cast(:trigger, %PinBinding{special_action: "dump_info"} = pin_binding) do
    ast(:rpc_request, %{label: "pin_binding.#{pin_binding.pin_num}"}, [ast(:dump_info, %{}, [])])
    |> CeleryScript.rpc_request(&handle_rpc_request(&1, pin_binding))
  end

  def handle_cast(:trigger, %PinBinding{special_action: "emergency_lock"} = pin_binding) do
    ast(:rpc_request, %{label: "pin_binding.#{pin_binding.pin_num}"}, [
      ast(:emergency_lock, %{}, [])
    ])
    |> CeleryScript.rpc_request(&handle_rpc_request(&1, pin_binding))
  end

  def handle_cast(:trigger, %PinBinding{special_action: "emergency_unlock"} = pin_binding) do
    ast(:rpc_request, %{label: "pin_binding.#{pin_binding.pin_num}"}, [
      ast(:emergency_unlock, %{}, [])
    ])
    |> CeleryScript.rpc_request(&handle_rpc_request(&1, pin_binding))
  end

  def handle_cast(:trigger, %PinBinding{special_action: "power_off"} = pin_binding) do
    ast(:rpc_request, %{label: "pin_binding.#{pin_binding.pin_num}"}, [ast(:power_off, %{}, [])])
    |> CeleryScript.rpc_request(&handle_rpc_request(&1, pin_binding))
  end

  def handle_cast(:trigger, %PinBinding{special_action: "read_status"} = pin_binding) do
    ast(:rpc_request, %{label: "pin_binding.#{pin_binding.pin_num}"}, [ast(:read_status, %{}, [])])
    |> CeleryScript.rpc_request(&handle_rpc_request(&1, pin_binding))
  end

  def handle_cast(:trigger, %PinBinding{special_action: "reboot"} = pin_binding) do
    ast(:rpc_request, %{label: "pin_binding.#{pin_binding.pin_num}"}, [ast(:reboot, %{}, [])])
    |> CeleryScript.rpc_request(&handle_rpc_request(&1, pin_binding))
  end

  def handle_cast(:trigger, %PinBinding{special_action: "sync"} = pin_binding) do
    ast(:rpc_request, %{label: "pin_binding.#{pin_binding.pin_num}"}, [ast(:sync, %{}, [])])
    |> CeleryScript.rpc_request(&handle_rpc_request(&1, pin_binding))
  end

  def handle_cast(:trigger, %PinBinding{special_action: "take_photo"} = pin_binding) do
    ast(:rpc_request, %{label: "pin_binding.#{pin_binding.pin_num}"}, [ast(:take_photo, %{}, [])])
    |> CeleryScript.rpc_request(&handle_rpc_request(&1, pin_binding))
  end

  def handle_cast(:trigger, %PinBinding{} = pin_binding) do
    Farmbot.Logger.error(1, "Unknown PinBinding: #{pin_binding}")
    {:noreply, pin_binding, :hibernate}
  end

  def handle_sequence_results({:error, reason}, %PinBinding{} = pin_binding) do
    Farmbot.Logger.error(1, "PinBinding #{pin_binding} failed to execute sequence: #{reason}")
  end

  def handle_sequence_results(_, _), do: :ok

  def handle_rpc_request(
        %{kind: :rpc_error, body: [%{args: %{message: m}}]},
        %PinBinding{} = pin_binding
      ) do
    Farmbot.Logger.error(1, "PinBinding: #{pin_binding} failed to execute special action: #{m}")
    {:noreply, pin_binding, :hibernate}
  end

  def handle_rpc_request(_, %PinBinding{} = pin_binding),
    do: {:noreply, pin_binding, :hibernate}
end
