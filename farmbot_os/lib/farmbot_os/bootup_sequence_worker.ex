defmodule FarmbotOS.BootupSequenceWorker do
  use GenServer
  require Logger
  require FarmbotCore.Logger
  alias FarmbotCore.{Asset, BotState, DepTracker}

  alias FarmbotCore.Asset.{
    FarmwareInstalation,
    Peripheral
  }

  alias FarmbotCeleryScript.AST

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    %{
      informational_settings: %{
        sync_status: sync_status,
        idle: fw_idle,
        firmware_version: fw_version,
        firmware_configured: fw_configured
      }
    } = BotState.subscribe()

    state = %{
      synced: sync_status == "synced",
      firmware_idle: fw_idle,
      firmware_version: fw_version,
      firmware_configured: fw_configured,
      sequence_id: nil,
      sequence_started_at: nil,
      sequence_completed_at: nil,
      sequence_ref: nil
    }

    # send self(), :checkup
    {:ok, state}
  end

  def handle_info(:checkup, state) do
    {:noreply, maybe_start_sequence(state)}
  end

  def handle_info(:start_sequence, %{sequence_id: id} = state) do
    case Asset.get_sequence(id) do
      nil ->
        FarmbotCore.Logger.error(1, """
        Farmbot could not execute it's configured bootup sequence. Maybe
        a sync is required?
        """)

        {:noreply, state}

      %{name: name} ->
        Logger.debug("bootup sequence start: #{inspect(state)}")
        FarmbotCore.Logger.busy(2, "Starting bootup sequence: #{name}")
        ref = make_ref()
        FarmbotCeleryScript.execute(execute_ast(id), ref)
        {:noreply, %{state | sequence_started_at: DateTime.utc_now(), sequence_ref: ref}}
    end
  end

  def handle_info({:step_complete, ref, :ok}, %{sequence_ref: ref} = state) do
    FarmbotCore.Logger.success(2, "Bootup sequence complete")
    {:noreply, %{state | sequence_completed_at: DateTime.utc_now()}}
  end

  def handle_info({:step_complete, ref, {:error, reason}}, %{sequence_ref: ref} = state) do
    FarmbotCore.Logger.error(2, "Bootup sequence failed: #{reason}")
    {:noreply, %{state | sequence_completed_at: DateTime.utc_now()}}
  end

  def handle_info(
        {BotState, %{changes: %{informational_settings: %{changes: %{idle: idle}}}}},
        state
      ) do
    state = maybe_start_sequence(%{state | firmware_idle: idle})
    {:noreply, state}
  end

  def handle_info(
        {BotState,
         %{changes: %{informational_settings: %{changes: %{firmware_version: fw_version}}}}},
        state
      ) do
    state = maybe_start_sequence(%{state | firmware_version: fw_version})
    {:noreply, state}
  end

  def handle_info(
        {BotState,
         %{changes: %{informational_settings: %{changes: %{firmware_configured: fw_configured}}}}},
        state
      ) do
    # this should really be fixed upstream not to dispatch if version is none.
    if state.firmware_version == "none" do
      {:noreply, state}
    else
      state = maybe_start_sequence(%{state | firmware_configured: fw_configured})
      {:noreply, state}
    end
  end

  def handle_info(
        {BotState, %{changes: %{informational_settings: %{changes: %{sync_status: "synced"}}}}},
        state
      ) do
    state = maybe_start_sequence(%{state | synced: true})
    {:noreply, state}
  end

  def handle_info({BotState, _}, state) do
    state = maybe_start_sequence(%{state | synced: true})
    {:noreply, state}
  end

  defp maybe_start_sequence(%{synced: false} = state), do: state
  defp maybe_start_sequence(%{firmware_version: "none"} = state), do: state
  defp maybe_start_sequence(%{firmware_idle: false} = state), do: state
  defp maybe_start_sequence(%{firmware_configured: false} = state), do: state
  defp maybe_start_sequence(%{sequence_started_at: %DateTime{}} = state), do: state
  defp maybe_start_sequence(%{sequence_completed_at: %DateTime{}} = state), do: state

  defp maybe_start_sequence(state) do
    case Asset.fbos_config() do
      %{boot_sequence_id: nil} ->
        state

      %{boot_sequence_id: id} ->
        dependency_assets_loaded?() && send(self(), :start_sequence)
        %{state | sequence_id: id}
    end
  end

  defp execute_ast(sequence_id) do
    AST.Factory.new()
    |> AST.Factory.rpc_request("fbos_config.bootup_sequence")
    |> AST.Factory.execute(sequence_id)
  end

  defp dependency_assets_loaded?() do
    peripherals =
      Enum.all?(DepTracker.get_asset(Peripheral), fn
        {{Peripheral, _}, :complete} ->
          true

        {{kind, id}, status} ->
          Logger.debug("bootup sequence still waiting on: #{kind}.#{id} status=#{status}")
          false
      end)

    farmware =
      Enum.all?(DepTracker.get_asset(FarmwareInstalation), fn
        {{FarmwareInstalation, _}, :complete} ->
          true

        {{kind, id}, status} ->
          Logger.debug("bootup sequence still waiting on: #{kind}.#{id} status=#{status}")
          false
      end)

    peripherals && farmware
  end
end
